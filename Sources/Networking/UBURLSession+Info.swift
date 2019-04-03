//
//  NetworkingTaskInfo.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

public struct NetworkingTaskInfo: CustomDebugStringConvertible {
    let metrics: URLSessionTaskMetrics

    init(metrics: URLSessionTaskMetrics) {
        self.metrics = metrics
    }

    public var debugDescription: String {
        return String(describing: metrics)
    }
}
