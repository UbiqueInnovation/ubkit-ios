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

    var reloadHeaders: [String: String] {
        switch self {
            case .miss: return [:]
            case .expired(cachedResponse: _, reloadHeaders: let h): return h
            case .hit(cachedResponse: _, reloadHeaders: let h): return h
        }
    }

    var cachedResponse: CachedURLResponse? {
        switch self {
            case .miss: return nil
            case .expired(cachedResponse: let r, reloadHeaders: _): return r
            case .hit(cachedResponse: let r, reloadHeaders: _): return r
        }
    }
}

/// A caching logic object can provide decision when comes to requests and response that needs caching
public protocol UBCachingLogic {
    /// Modify the request before starting
    /// Allows to change the cache policy
    func prepareRequest(_ request: inout URLRequest)

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
    ///   - error: Error if the request failed
    /// - Returns: A possible caching response
    func proposeCachedResponse(for session: URLSession, dataTask: URLSessionDataTask, ubDataTask: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?, error: Error?) -> CachedURLResponse?

    /// Asks the caching logic to provide a cached proposition based on an existing cached response but with updating the relevent fields based on a newer request.
    ///
    /// Typically this is called when a cache hits and the backend returns a `not-modified` response
    ///
    /// - Parameters:
    ///   - currentCachedResponse: The current cached response
    ///   - newResponse: The updated HTTP response
    func proposeUpdatedCachedResponse(_ currentCachedResponse: CachedURLResponse, newResponse: HTTPURLResponse) -> CachedURLResponse?

    /// Asks the caching logic for a cached result
    ///
    /// - Parameters:
    ///   - session: The session asking
    ///   - request: The request to check for cached response
    ///   - dataTask: The associated UB data task
    /// - Returns: A cached result
    func cachedResponse(_ session: URLSession, request: URLRequest, dataTask: UBURLDataTask) -> UBCacheResult

    /// Tell the caching logic that the cache had no result
    func hasMissedCache(dataTask: UBURLDataTask)

    /// Tell the caching logic that the result was used
    func hasUsed(cachedResponse: HTTPURLResponse, nonModifiedResponse: HTTPURLResponse?, metrics: URLSessionTaskMetrics?, request _: URLRequest, dataTask: UBURLDataTask)

    /// Tell the caching logic that a new result was cached
    func hasProposedCachedResponse(cachedURLResponse: CachedURLResponse?, response: HTTPURLResponse, session: URLSession, request: URLRequest, ubDataTask: UBURLDataTask, metrics: URLSessionTaskMetrics?)
}
