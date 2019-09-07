//
//  NetworkingTaskInfo.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

/// Holds information on the networking task
public struct UBNetworkingTaskInfo: CustomDebugStringConvertible {
    /// The metric collected for the task
    public let metrics: URLSessionTaskMetrics?

    /// `true` if the response was returned from cache
    public let cacheHit: Bool

    /// `true` if the response was returned from cron refresh
    public let refresh: Bool

    /// Instansiate a network info
    init(metrics: URLSessionTaskMetrics?, cacheHit: Bool, refresh: Bool) {
        self.metrics = metrics
        self.cacheHit = cacheHit
        self.refresh = refresh
    }

    /// :nodoc:
    public var debugDescription: String {
        let cacheDescription = "Cache \(cacheHit ? "Hit" : "Miss") \(refresh ? "Refresh" : "First")"
        if let metrics = metrics {
            return String(describing: metrics) + "\n" + cacheDescription
        } else {
            return cacheDescription
        }
    }
}
