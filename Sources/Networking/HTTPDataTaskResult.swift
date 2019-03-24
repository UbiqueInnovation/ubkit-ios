//
//  HTTPDataTaskResult.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// An HTTP data result
public enum HTTPDataTaskResult<T>: CustomDebugStringConvertible {
    /// The data task failed
    case failure(Error)
    /// The data task succeeded
    case success(T)
    /// The data task succeeded but without any data
    case successEmptyBody

    public var debugDescription: String {
        switch self {
        case let .failure(error):
            return "Data task failed with error: \(error)"
        case let .success(data):
            return "Data task succeeded with \(T.self): \(String(describing: data))"
        case .successEmptyBody:
            return "Data task succeeded with no body"
        }
    }
}
