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
    public let metrics: URLSessionTaskMetrics

    /// Instansiate a network info
    init(metrics: URLSessionTaskMetrics) {
        self.metrics = metrics
    }

    /// :nodoc:
    public var debugDescription: String {
        return String(describing: metrics)
    }
}
