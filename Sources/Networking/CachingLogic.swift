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
