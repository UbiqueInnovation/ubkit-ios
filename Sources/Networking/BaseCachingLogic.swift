//
//  BaseCachingLogic.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 28.05.19.
//

import Foundation

/// A class that provides auto refreshing caching logic
open class UBBaseCachingLogic: UBCachingLogic {
    /// The date formatter to use
    open var dateFormatter: DateFormatter

    /// The storage policy
    public let storagePolicy: URLCache.StoragePolicy

    /// The quality of service
    public let qos: DispatchQoS

    private let UserInfoKeyMetrics = "UserInfoKeyMetrics"

    /// Initializes the caching logic with a policy and a quality of service
    ///
    /// - Parameters:
    ///   - storagePolicy: The storage policy
    ///   - qos: The quality of service
    public init(storagePolicy: URLCache.StoragePolicy = .allowed, qos: DispatchQoS = .default) {
        self.storagePolicy = storagePolicy
        self.qos = qos

        // Initialize the date formatter
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        dateFormatter = df
    }

    /// Gets a cached url response from a url session.
    ///
    /// - Parameters:
    ///   - urlSession: The url session to get the cache from
    ///   - request: The request to check for a cached version
    /// - Returns: A cached response if found
    open func getCachedResponseFromSession(_ urlSession: URLSession, for request: URLRequest) -> CachedURLResponse? {
        guard let urlCache = urlSession.configuration.urlCache else {
            return nil
        }
        return urlCache.cachedResponse(for: request)
    }

    /// :nodoc:
    open func proposeCachedResponse(for session: URLSession, dataTask _: URLSessionDataTask, ubDataTask: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?) -> CachedURLResponse? {
        if let cacheControlHeader = response.allHeaderFields[cacheControlHeaderFieldName] as? String, let cacheControlDirectives = UBCacheResponseDirectives(cacheControlHeader: cacheControlHeader) {
            guard cacheControlDirectives.cachingAllowed else {
                return nil
            }
        } else if response.allHeaderFields[nextRefreshHeaderFieldName] == nil, response.allHeaderFields[expiresHeaderFieldName] == nil {
            // if no cache control headers are set, don't store the cached the response
            // unless some other cron-logic headers are in use
            return nil
        }

        // Check the status code
        let statusCodeCategory = UBHTTPCodeCategory(code: response.statusCode)
        switch statusCodeCategory {
        case .serverError, .informational, .redirection, .clientError, .uncategorized:
            // If not success then no caching
            return nil
        case .success:
            guard let data = data else {
                return nil
            }
            // If successful then cache the data
            var userInfo = [AnyHashable: Any]()
            if let metrics = metrics {
                userInfo[UserInfoKeyMetrics] = metrics
            }
            let cachedResponse = CachedURLResponse(response: response, data: data, userInfo: userInfo, storagePolicy: storagePolicy)
            return cachedResponse
        }
    }

    /// :nodoc:
    open func cachedResponse(_ session: URLSession, request: URLRequest, dataTask _: UBURLDataTask) -> UBCacheResult {
        guard let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request) else {
            // No URL Cache, then always miss
            return .miss
        }

        /// Make sure we have the caching headers and it was allowed to cache the response in the first place
        guard let response = cachedResponse.response as? HTTPURLResponse, response.statusCode == UBHTTPCodeCategory.success else {
            session.configuration.urlCache?.removeCachedResponse(for: request)
            return .miss
        }
        if let cacheControlHeader = response.allHeaderFields[cacheControlHeaderFieldName] as? String,
            let cacheControlDirectives = UBCacheResponseDirectives(cacheControlHeader: cacheControlHeader) {
            guard cacheControlDirectives.cachingAllowed else {
                session.configuration.urlCache?.removeCachedResponse(for: request)
                return .miss
            }
        } else if response.allHeaderFields[nextRefreshHeaderFieldName] == nil, response.allHeaderFields[expiresHeaderFieldName] == nil {
            // if no cache control headers are set, don't use the cached the response
            // unless some other cron-logic headers are in use
            return .miss
        }

        // Check that the content language of the cached response is contained in the request accepted language
        if let contentLanguage = response.allHeaderFields[contentLanguageHeaderFieldName] as? String,
            let acceptLanguage = request.allHTTPHeaderFields?[acceptedLanguageHeaderFieldName],
            acceptLanguage.lowercased().contains(contentLanguage.lowercased()) == false {
            return .miss
        }

        // Load metrics from last request
        let metrics = cachedResponse.userInfo?[UserInfoKeyMetrics] as? URLSessionTaskMetrics

        // Setup reload headers
        var reloadHeaders: [String: String] = [:]
        if let lastModified = response.allHeaderFields[lastModifiedHeaderFieldName] as? String {
            reloadHeaders[ifModifiedSinceHeaderFieldName] = lastModified
        }
        if let etag = response.allHeaderFields[eTagHeaderFieldName] as? String {
            reloadHeaders[ifNoneMatchHeaderFieldName] = etag
        }

        // Check Max Age
        if let cacheControlHeader = response.allHeaderFields[cacheControlHeaderFieldName] as? String,
            let cacheControlDirectives = UBCacheResponseDirectives(cacheControlHeader: cacheControlHeader), let maxAge = cacheControlDirectives.maxAge, let responseDateHearder = response.allHeaderFields[dateHeaderFieldName] as? String, let responseDate = dateFormatter.date(from: responseDateHearder) {
            // cacheAge: Round up to next seconds
            // Rounding is important s.t. re-requests with interval < 1s are not
            // treated differently that requests after > 1s
            let cacheAge = Int(ceil(-responseDate.timeIntervalSinceNow))

            if cacheAge < 0 {
                return .miss
            } else if cacheAge > maxAge {
                return .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics)
            } else {
                return .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics)
            }

            // If there are no max age then search for expire header
        } else if let expiresHeader = response.allHeaderFields[expiresHeaderFieldName] as? String,
            let expiresDate = dateFormatter.date(from: expiresHeader) {
            if expiresDate < Date() {
                return .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics)
            } else {
                return .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics)
            }

            // If there is no max age neither expires, set a cache validity default
        } else if let responseDateHearder = response.allHeaderFields[dateHeaderFieldName] as? String, let responseDate = dateFormatter.date(from: responseDateHearder) {
            // Fallback to a month of caching
            let calendar = Calendar(identifier: .gregorian)
            guard let defaultCachingLimit = calendar.date(byAdding: .month, value: 1, to: responseDate) else {
                return .miss
            }
            if defaultCachingLimit < Date() {
                return .expired(cachedResponse: cachedResponse, reloadHeaders: [:], metrics: metrics)
            } else {
                return .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics)
            }

            // In case no caching information is found just remove the cached object
        } else {
            session.configuration.urlCache?.removeCachedResponse(for: request)
            return .miss
        }
    }

    /// :nodoc:
    public func hasMissedCache(dataTask _: UBURLDataTask) {
        // don't care, subclasses might
    }

    /// :nodoc:
    public func hasUsed(response: HTTPURLResponse, metrics: URLSessionTaskMetrics?, request _: URLRequest, dataTask: UBURLDataTask) {
        // don't care, subclasses might
    }

    /// :nodoc:
    public func hasProposedCachedResponse(cachedURLResponse _: CachedURLResponse?, response _: HTTPURLResponse, session _: URLSession, request _: URLRequest, ubDataTask _: UBURLDataTask, metrics _: URLSessionTaskMetrics?) {
        // don't care, subclasses might
    }

    // MARK: - Header fields keys

    /// The next refresh header field name
    open var nextRefreshHeaderFieldName: String {
        return "X-Next-Refresh"
    }

    /// The backoff interval header field name
    open var backoffIntervalHeaderFieldName: String {
        return "Backoff"
    }

    /// The cache control header field name
    open var cacheControlHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.cacheControl.rawValue
    }

    /// The expires header field name
    open var expiresHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.expires.rawValue
    }

    /// The age header field name
    open var ageHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.age.rawValue
    }

    /// The date header field name
    open var dateHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.date.rawValue
    }

    /// The accepted language header field name
    open var acceptedLanguageHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.acceptLanguage.rawValue
    }

    /// The content language header field name
    open var contentLanguageHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.contentLanguage.rawValue
    }

    /// The eTag header field name
    open var eTagHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.etag.rawValue
    }

    /// The if none match header field name
    open var ifNoneMatchHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.ifNoneMatch.rawValue
    }

    /// The if modified since header field name
    open var ifModifiedSinceHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.ifModifiedSince.rawValue
    }

    /// The last modified header field name
    open var lastModifiedHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.lastModified.rawValue
    }
}
