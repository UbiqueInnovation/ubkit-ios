//
//  UBURLSession+Info.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

/// Holds information on the networking task
public struct UBNetworkingTaskInfo: CustomDebugStringConvertible, Sendable {
// Apple linker has a bug that prevents the `URLSessionTaskMetrics` to be correctly linked
// Althow it is marked as available from watchOS 3.0 and up
#if !os(watchOS)
    /// The metric collected for the task
    /// NM - 17.1.2020: This API is a really working as expected in combination with caching and cron and we dont need it right now
    /// I'll set it to private, we can make it public when we have an actual usecase
    private let metrics: URLSessionTaskMetrics?
#endif

    /// `true` if the response was returned from cache
    public let cacheHit: Bool

    /// `true` if the response was returned from cron refresh
    public let refresh: Bool

#if os(watchOS)
    init(cacheHit: Bool, refresh: Bool) {
        self.cacheHit = cacheHit
        self.refresh = refresh
    }

#else
    /// Instansiate a network info
    init(metrics: URLSessionTaskMetrics?, cacheHit: Bool, refresh: Bool) {
        self.metrics = metrics
        self.cacheHit = cacheHit
        self.refresh = refresh
    }
#endif

    /// :nodoc:
    public var debugDescription: String {
        let cacheDescription = "Cache \(cacheHit ? "Hit" : "Miss") \(refresh ? "Refresh" : "First")"
#if os(watchOS)
        return cacheDescription
#else
        if let metrics {
            return String(describing: metrics) + "\n" + cacheDescription
        } else {
            return cacheDescription
        }
#endif
    }
}
