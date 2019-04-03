//
//  UBHTTPURLResponse.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

public class UBHTTPURLResponse: CustomStringConvertible, CustomDebugStringConvertible {
    public let response: HTTPURLResponse
    public let metrics: URLSessionTaskMetrics?

    public init(response: HTTPURLResponse, metrics: URLSessionTaskMetrics?) {
        self.response = response
        self.metrics = metrics
    }

    public var debugDescription: String {
        if let metrics = metrics {
            return String(describing: metrics)
        } else {
            return response.debugDescription
        }
    }

    public var description: String {
        return response.description
    }
}
