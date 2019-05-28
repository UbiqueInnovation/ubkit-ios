//
//  CachingLogic.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 04.04.19.
//

import Foundation

// TODO: Cancelation of the task + change request monitoring

/// The cache result
public enum UBCacheResult {
    /// The cache missed
    case miss
    /// Cached data found but is expired
    case expired(cachedResponse: CachedURLResponse, reloadHeaders: [String: String])
    /// Cached data found and is valid
    case hit(cachedResponse: CachedURLResponse, reloadHeaders: [String: String])
}

/// A caching logic object can provide decision when comes to requests and response that needs caching
public protocol UBCachingLogic {
    /// Asks the caching logic to provide a cached proposition.
    ///
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
    func proposeCachedResponse(for session: URLSession, dataTask: URLSessionDataTask, ubDataTask: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?) -> CachedURLResponse?
    
    /// Asks the caching logic for a cached result
    ///
    /// - Parameters:
    ///   - session: The session asking
    ///   - request: The request to check for cached response
    ///   - dataTask: The associated UB data task
    /// - Returns: A cached result
    func cachedResponse(_ session: URLSession, request: URLRequest, dataTask: UBURLDataTask) -> UBCacheResult
}

/// A class that provides auto refreshing caching logic
open class UBAutoRefreshCacheLogic: UBCachingLogic {
    private let refreshJobs = NSMapTable<UBURLDataTask, UBCronJob>(keyOptions: .weakMemory, valueOptions: .strongMemory)

    open var nextRefreshHeaderFieldName: String {
        return "X-Next-Refresh"
    }

    open var backoffHeaderFieldName: String {
        return "Backoff"
    }

    open var cacheControlHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.cacheControl.rawValue
    }

    open var expiresHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.expires.rawValue
    }

    open var ageHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.age.rawValue
    }

    open var dateHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.date.rawValue
    }

    open var acceptedLanguageHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.acceptLanguage.rawValue
    }

    open var contentLanguageHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.contentLanguage.rawValue
    }

    open var eTagHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.etag.rawValue
    }

    open var ifNoneMatchHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.ifNoneMatch.rawValue
    }

    open var ifModifiedSinceHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.ifModifiedSince.rawValue
    }

    open var lastModifiedHeaderFieldName: String {
        return UBHTTPHeaderField.StandardKeys.lastModified.rawValue
    }

    open var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return df
    }

    public let storagePolicy: URLCache.StoragePolicy
    public let autoRefreshExpiredCache: Bool

    private let qos: DispatchQoS

    public init(autoRefreshExpiredCache: Bool = true, storagePolicy: URLCache.StoragePolicy = .allowed, qos: DispatchQoS = .default) {
        self.storagePolicy = storagePolicy
        self.qos = qos
        self.autoRefreshExpiredCache = autoRefreshExpiredCache
    }

    open func getCachedResponseFromSession(_ urlSession: URLSession, for request: URLRequest) -> CachedURLResponse? {
        guard let urlCache = urlSession.configuration.urlCache else {
            return nil
        }
        return urlCache.cachedResponse(for: request)
    }

    open func proposeCachedResponse(for session: URLSession, dataTask _: URLSessionDataTask, ubDataTask: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?) -> CachedURLResponse? {
        cancelRefreshCronJob(for: ubDataTask)

        guard let cacheControlHeader = response.allHeaderFields[cacheControlHeaderFieldName] as? String, let cacheControlDirectives = UBCacheResponseDirectives(cacheControlHeader: cacheControlHeader), cacheControlDirectives.cachingAllowed else {
            return nil
        }

        // Check the status code
        let statusCodeCategory = UBHTTPCodeCategory(code: response.statusCode)
        switch statusCodeCategory {
        case .serverError, .informational, .clientError, .uncategorized:
            return nil
        case .redirection:
            guard response == UBStandardHTTPCode.notModified else {
                return nil
            }
            scheduleRefreshCronJobIfNeeded(for: ubDataTask, headers: response.allHeaderFields)
            return nil
        case .success:
            guard let data = data else {
                return nil
            }

            let cachedResponse = CachedURLResponse(response: response, data: data, userInfo: nil, storagePolicy: storagePolicy)
            scheduleRefreshCronJobIfNeeded(for: ubDataTask, headers: response.allHeaderFields)
            return cachedResponse
        }
    }

    private func cancelRefreshCronJob(for task: UBURLDataTask) {
        refreshJobs.removeObject(forKey: task)
    }

    private func scheduleRefreshCronJobIfNeeded(for task: UBURLDataTask, headers: [AnyHashable: Any]) {
        guard autoRefreshExpiredCache, let nextRefreshDate = cachedResponseNextRefreshDate(headers) else {
            return
        }
        cancelRefreshCronJob(for: task)
        // Schedule a new job
        return
        let job = UBCronJob(fireAt: nextRefreshDate, qos: qos) { [weak task] in
            task?.start()
        }
        refreshJobs.setObject(job, forKey: task)
    }

    open func cachedResponseNextRefreshDate(_ allHeaderFields: [AnyHashable: Any]) -> Date? {
        guard let responseDateHeader = allHeaderFields[dateHeaderFieldName] as? String, let responseDate = dateFormatter.date(from: responseDateHeader) else {
            return nil
        }
        guard let nextRefreshDateHeader = allHeaderFields[nextRefreshHeaderFieldName] as? String, let nextRefreshDate = dateFormatter.date(from: nextRefreshDateHeader) else {
            return nil
        }

        // This is the date that we are not allowed to make requests before.
        let backoffDate: Date
        if let backoffHeader = allHeaderFields[backoffHeaderFieldName] as? String, let backoffHeaderParsed = TimeInterval(backoffHeader) {
            backoffDate = responseDate + backoffHeaderParsed
        } else {
            // If none is specified then we can assume it is always allowed to make requests
            backoffDate = Date(timeIntervalSinceNow: 60)
        }

        if nextRefreshDate > backoffDate {
            return nextRefreshDate
        } else {
            return backoffDate
        }
    }

    open func cachedResponse(_ session: URLSession, request: URLRequest, dataTask: UBURLDataTask) -> UBCacheResult {
        guard let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request) else {
            return .miss
        }

        guard let response = cachedResponse.response as? HTTPURLResponse,
            let cacheControlHeader = response.allHeaderFields[cacheControlHeaderFieldName] as? String,
            let cacheControlDirectives = UBCacheResponseDirectives(cacheControlHeader: cacheControlHeader),
            cacheControlDirectives.cachingAllowed,
            response.statusCode == UBHTTPCodeCategory.success else {
            session.configuration.urlCache?.removeCachedResponse(for: request)
            cancelRefreshCronJob(for: dataTask)
            return .miss
        }

        // Check that the content language of the cached response is contained in the request accepted language
        if let contentLanguage = response.allHeaderFields[contentLanguageHeaderFieldName] as? String,
            let acceptLanguage = request.allHTTPHeaderFields?[acceptedLanguageHeaderFieldName],
            acceptLanguage.lowercased().contains(contentLanguage.lowercased()) == false {
            cancelRefreshCronJob(for: dataTask)
            return .miss
        }

        // Setup reload headers
        var reloadHeaders: [String: String] = [:]
        if let lastModified = response.allHeaderFields[lastModifiedHeaderFieldName] as? String {
            reloadHeaders[ifModifiedSinceHeaderFieldName] = lastModified
        }
        if let etag = response.allHeaderFields[eTagHeaderFieldName] as? String {
            reloadHeaders[ifNoneMatchHeaderFieldName] = etag
        }

        // Check Max Age
        if let maxAge = cacheControlDirectives.maxAge, let responseDateHearder = response.allHeaderFields[dateHeaderFieldName] as? String, let responseDate = dateFormatter.date(from: responseDateHearder) {
            let cacheAge = Int(-responseDate.timeIntervalSinceNow)
            if cacheAge < 0 {
                cancelRefreshCronJob(for: dataTask)
                return .miss
            } else if cacheAge > maxAge {
                scheduleRefreshCronJobIfNeeded(for: dataTask, headers: response.allHeaderFields)
                return .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders)
            } else {
                scheduleRefreshCronJobIfNeeded(for: dataTask, headers: response.allHeaderFields)
                return .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders)
            }

            // If there are no max age then search for expire header
        } else if let expiresHeader = response.allHeaderFields[expiresHeaderFieldName] as? String,
            let expiresDate = dateFormatter.date(from: expiresHeader) {
            if expiresDate > Date() {
                scheduleRefreshCronJobIfNeeded(for: dataTask, headers: response.allHeaderFields)
                return .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders)
            } else {
                scheduleRefreshCronJobIfNeeded(for: dataTask, headers: response.allHeaderFields)
                return .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders)
            }

            // If there is no max age neither expires, set a cache validity default
        } else if let responseDateHearder = response.allHeaderFields[dateHeaderFieldName] as? String, let responseDate = dateFormatter.date(from: responseDateHearder) {
            // Fallback to a month of caching
            let calendar = Calendar(identifier: .gregorian)
            guard let defaultCachingLimit = calendar.date(byAdding: .month, value: 1, to: responseDate) else {
                cancelRefreshCronJob(for: dataTask)
                return .miss
            }
            if defaultCachingLimit < Date() {
                scheduleRefreshCronJobIfNeeded(for: dataTask, headers: response.allHeaderFields)
                return .expired(cachedResponse: cachedResponse, reloadHeaders: [:])
            } else {
                scheduleRefreshCronJobIfNeeded(for: dataTask, headers: response.allHeaderFields)
                return .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders)
            }

            // In case no caching information is found just remove the cached object
        } else {
            session.configuration.urlCache?.removeCachedResponse(for: request)
            cancelRefreshCronJob(for: dataTask)
            return .miss
        }
    }
}
