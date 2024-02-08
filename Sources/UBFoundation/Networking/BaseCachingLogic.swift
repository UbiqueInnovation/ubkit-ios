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
    private let UserInfoKeyMethod = "UserInfoKeyMethod"

    private let UserInfoKeyAcceptLanguage = "Accept-Language"

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

    public func prepareRequest(_ request: inout URLRequest) {
        request.cachePolicy = .reloadIgnoringLocalCacheData
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
    public func proposeUpdatedCachedResponse(_ currentCachedResponse: CachedURLResponse, newResponse: HTTPURLResponse) -> CachedURLResponse? {
        guard let httpURLResponse = currentCachedResponse.response as? HTTPURLResponse,
              let mutableResponse = HTTPMutableURLResponse(httpURLResponse) else {
            return nil
        }

        // Override header fields only if present in the new response
        for (key, value) in newResponse.allHeaderFields {
            guard let key = key as? String, let value = value as? String else {
                continue
            }
            mutableResponse.setHeaderField(value: value, key: key)
        }
        guard let newCacheResponse = mutableResponse.urlResponse else {
            return nil
        }
        return CachedURLResponse(response: newCacheResponse, data: currentCachedResponse.data, userInfo: currentCachedResponse.userInfo, storagePolicy: currentCachedResponse.storagePolicy)
    }

    /// :nodoc:
    public func proposeCachedResponse(for session: URLSession, dataTask: URLSessionDataTask, ubDataTask: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?, error: Error?) -> CachedURLResponse? {
        // Don't cache request errors
        if error != nil {
            return nil
        }
        // Check the status code
        let statusCodeCategory = UBHTTPCodeCategory(code: response.statusCode)
        switch statusCodeCategory {
            case .serverError, .informational, .redirection, .clientError, .uncategorized:
                // If not success then no caching
                return nil
            case .success:
                guard let encapsulatedData = proposedCacheResponseWhenSuccessfull(for: session, dataTask: dataTask, ubDataTask: ubDataTask, request: request, response: response, data: data, metrics: metrics) else {
                    return nil
                }
                let cachedResponse = CachedURLResponse(response: encapsulatedData.response, data: encapsulatedData.data, userInfo: encapsulatedData.userInfo, storagePolicy: storagePolicy)
                return cachedResponse
        }
    }

    /// Asks the caching logic if data should be stored in the cache
    /// The default implementation returns true iff allowed
    /// Subclass may return true for all data to cache more data
    open func shouldWriteToCache(allowed: Bool, data _: Data, response _: HTTPURLResponse) -> Bool {
        allowed
    }

    /// Asks the caching logic to provide a cached proposition when successfull.
    ///
    /// This function allows the subclassing to customize the proposed cache response in case of a successful response.
    /// Override this function to change the logic of caching
    /// Returning `nil` will indicate that the response should not be cached
    ///
    /// - Parameters:
    ///   - session: The session that generated the response
    ///   - dataTask: The data task that generated the response
    ///   - ubDataTask: The UBDataTask that wrappes the data task
    ///   - request: The latest request
    ///   - response: The latest response
    ///   - data: The data returned by the response
    ///   - metrics: The metrics collected by the session during the request
    /// - Returns: A possible caching response
    open func proposedCacheResponseWhenSuccessfull(for _: URLSession, dataTask _: URLSessionDataTask, ubDataTask _: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?) -> (response: HTTPURLResponse, data: Data, userInfo: [AnyHashable: Any])? {
        // Note: Data can be nil, if a successful response body was empty
        let data = data ?? Data()

        if let cacheControlHeader = response.ub_getHeaderField(key: cacheControlHeaderFieldName), let cacheControlDirectives = UBCacheResponseDirectives(cacheControlHeader: cacheControlHeader) {
            if !cacheControlDirectives.cachingAllowed {
                if !shouldWriteToCache(allowed: false, data: data, response: response) {
                    return nil
                }
            }
        }

        if !shouldWriteToCache(allowed: true, data: data, response: response) {
            return nil
        }

        // If successful then cache the data
        var userInfo = [AnyHashable: Any]()
        if let metrics = metrics {
//            userInfo[UserInfoKeyMetrics] = metrics
        }
        if let headers = request.allHTTPHeaderFields,
           let acceptHeader = headers.getCaseInsensitiveValue(key: acceptedLanguageHeaderFieldName) {
            userInfo[UserInfoKeyAcceptLanguage] = acceptHeader
        }
        userInfo[UserInfoKeyMethod] = request.httpMethod

        return (response, data, userInfo)
    }

    /// Modify decision on whether cached result can still be used
    /// - Parameters
    ///     - proposed: The cache result from the caching logic
    ///     - possible: A `.hit` cache result that could be used if logic didn't decide for `.miss` or `.expired`
    ///     - reason: Why the proposed result was chosen
    /// - Returns: The cached result that will be returned from the networking Task
    ///
    /// Most common usage will be to return `possible` for all cases to enable cache forever or replace a `.expired` with `.hit` based on age to extend cache duration
    open func modifyCacheResult(proposed: UBCacheResult, possible _: UBCacheResult, reason _: CacheDecisionReason) -> UBCacheResult {
        proposed
    }

    /// Different decisions that can be made by caching logic
    public enum CacheDecisionReason {
        case cachingNotAllowed
        case contentLanguageNotAccepted(_ language: String)
        case negativeCacheAge(cacheAge: Int)
        case cacheAgeOlderMax(cacheAge: Int, maxAge: Int)
        case cacheAgeYoungerMax(cacheAge: Int, maxAge: Int)
        case expiredInPast(expiresDate: Date)
        case expiresInFuture(expiresDate: Date)
        case noCacheHeaders
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

        /// Make sure the cached response uses the same HTTP method
        if let httpMethod = cachedResponse.userInfo?[UserInfoKeyMethod] as? String,
           httpMethod != request.httpMethod {
            return .miss
        }

        // Load metrics from last request
        let metrics = cachedResponse.userInfo?[UserInfoKeyMetrics] as? URLSessionTaskMetrics

        // Setup reload headers
        var reloadHeaders: [String: String] = [:]
        if let lastModified = response.ub_getHeaderField(key: lastModifiedHeaderFieldName) {
            reloadHeaders[ifModifiedSinceHeaderFieldName] = lastModified
        }
        if let etag = response.ub_getHeaderField(key: eTagHeaderFieldName) {
            reloadHeaders[ifNoneMatchHeaderFieldName] = etag
        }

        let possibleResult = UBCacheResult.hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics)

        if let cacheControlHeader = response.ub_getHeaderField(key: cacheControlHeaderFieldName),
           let cacheControlDirectives = UBCacheResponseDirectives(cacheControlHeader: cacheControlHeader) {
            guard cacheControlDirectives.cachingAllowed else {
                let result = modifyCacheResult(proposed: .miss, possible: possibleResult, reason: .cachingNotAllowed)
                if case .miss = result {
                    session.configuration.urlCache?.removeCachedResponse(for: request)
                }
                return result
            }
        }

        // Get the content language from the cached response header. If no language header was stored, assume that the content was cached in the language of the accept header
        let contentLanguage = response.ub_getHeaderField(key: contentLanguageHeaderFieldName) ?? (cachedResponse.userInfo?[UserInfoKeyAcceptLanguage] as? String)
        // Check that the content language of the cached response is contained in the request accepted language
        if let contentLanguage = contentLanguage,
           let acceptLanguage = request.value(forHTTPHeaderField: acceptedLanguageHeaderFieldName),
           acceptLanguage.lowercased().contains(contentLanguage.lowercased()) == false {
            return modifyCacheResult(proposed: .miss, possible: possibleResult, reason: .contentLanguageNotAccepted(contentLanguage))
        }

        // Check Max Age
        if let cacheControlHeader = response.ub_getHeaderField(key: cacheControlHeaderFieldName),
           let cacheControlDirectives = UBCacheResponseDirectives(cacheControlHeader: cacheControlHeader), let maxAge = cacheControlDirectives.maxAge, let responseDateHearder = response.ub_getHeaderField(key: dateHeaderFieldName), let responseDate = dateFormatter.date(from: responseDateHearder) {
            // cacheAge: Round up to next seconds
            // Rounding is important s.t. re-requests with interval < 1s are not
            // treated differently that requests after > 1s
            let cacheAge = Int(ceil(-responseDate.timeIntervalSinceNow))

            if cacheAge < 0 {
                return modifyCacheResult(proposed: .miss, possible: possibleResult, reason: .negativeCacheAge(cacheAge: cacheAge))
            } else if cacheAge > maxAge {
                return modifyCacheResult(proposed: .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics), possible: possibleResult, reason: .cacheAgeOlderMax(cacheAge: cacheAge, maxAge: maxAge))
            } else {
                return modifyCacheResult(proposed: .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics), possible: possibleResult, reason: .cacheAgeYoungerMax(cacheAge: cacheAge, maxAge: maxAge))
            }

            // If there are no max age then search for expire header
        } else if let expiresHeader = response.ub_getHeaderField(key: expiresHeaderFieldName),
                  let expiresDate = dateFormatter.date(from: expiresHeader) {
            if expiresDate < Date() {
                return modifyCacheResult(proposed: .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics), possible: possibleResult, reason: .expiredInPast(expiresDate: expiresDate))
            } else {
                return modifyCacheResult(proposed: .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics), possible: possibleResult, reason: .expiresInFuture(expiresDate: expiresDate))
            }

            // If there is no max age neither expires, don't cache
        } else if let responseDateHearder = response.ub_getHeaderField(key: dateHeaderFieldName), let responseDate = dateFormatter.date(from: responseDateHearder) {
            // We could do heuristic caching, but behaviour could be unexpected
            return modifyCacheResult(proposed: .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: metrics), possible: possibleResult, reason: .noCacheHeaders)

            // In case no caching information is found just remove the cached object
        } else {
            let result = modifyCacheResult(proposed: .miss, possible: possibleResult, reason: .noCacheHeaders)
            if case .miss = result {
                session.configuration.urlCache?.removeCachedResponse(for: request)
            }
            return result
        }
    }

    /// :nodoc:
    public func hasMissedCache(dataTask _: UBURLDataTask) {
        // don't care, subclasses might
    }

    /// :nodoc:
    public func hasUsed(cachedResponse _: HTTPURLResponse, nonModifiedResponse _: HTTPURLResponse?, metrics _: URLSessionTaskMetrics?, request _: URLRequest, dataTask _: UBURLDataTask) {
        // don't care, subclasses might
    }

    /// :nodoc:
    public func hasProposedCachedResponse(cachedURLResponse _: CachedURLResponse?, response _: HTTPURLResponse, session _: URLSession, request _: URLRequest, ubDataTask _: UBURLDataTask, metrics _: URLSessionTaskMetrics?) {
        // don't care, subclasses might
    }

    // MARK: - Header fields keys

    /// The next refresh header field name
    open var nextRefreshHeaderFieldName: [String] {
        [UBHTTPHeaderField.StandardKeys.nextRefresh.rawValue, UBHTTPHeaderField.AmazonKeys.nextRefresh.rawValue, UBHTTPHeaderField.MSKeys.nextRefresh.rawValue]
    }

    /// The backoff interval header field name
    open var backoffIntervalHeaderFieldName: [String] {
        [UBHTTPHeaderField.StandardKeys.backoff.rawValue, UBHTTPHeaderField.AmazonKeys.backoff.rawValue, UBHTTPHeaderField.MSKeys.backoff.rawValue]
    }

    /// The cache control header field name
    open var cacheControlHeaderFieldName: [String] {
        [UBHTTPHeaderField.StandardKeys.cacheControl.rawValue, UBHTTPHeaderField.AmazonKeys.cacheControl.rawValue]
    }

    /// The expires header field name
    open var expiresHeaderFieldName: [String] {
        [UBHTTPHeaderField.StandardKeys.expires.rawValue, UBHTTPHeaderField.AmazonKeys.expires.rawValue, UBHTTPHeaderField.MSKeys.expires.rawValue]
    }

    /// The age header field name
    open var ageHeaderFieldName: String {
        UBHTTPHeaderField.StandardKeys.age.rawValue
    }

    /// The date header field name
    open var dateHeaderFieldName: String {
        UBHTTPHeaderField.StandardKeys.date.rawValue
    }

    /// The accepted language header field name
    open var acceptedLanguageHeaderFieldName: String {
        UBHTTPHeaderField.StandardKeys.acceptLanguage.rawValue
    }

    /// The content language header field name
    open var contentLanguageHeaderFieldName: String {
        UBHTTPHeaderField.StandardKeys.contentLanguage.rawValue
    }

    /// The eTag header field name
    open var eTagHeaderFieldName: String {
        UBHTTPHeaderField.StandardKeys.etag.rawValue
    }

    /// The if none match header field name
    open var ifNoneMatchHeaderFieldName: String {
        UBHTTPHeaderField.StandardKeys.ifNoneMatch.rawValue
    }

    /// The if modified since header field name
    open var ifModifiedSinceHeaderFieldName: String {
        UBHTTPHeaderField.StandardKeys.ifModifiedSince.rawValue
    }

    /// The last modified header field name
    open var lastModifiedHeaderFieldName: String {
        UBHTTPHeaderField.StandardKeys.lastModified.rawValue
    }
}
