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

    /// :nodoc:
    public var debugDescription: String {
        switch self {
        case let .failure(error):
            return "Data task failed with error: \(error)"
        case let .success(data):
            return "Data task succeeded with \(T.self): \(String(describing: data))"
        }
    }
}

/// An HTTP empty data result
public enum HTTPDataTaskNullableResult: CustomDebugStringConvertible {
    /// The data task failed
    case failure(Error)
    /// The data task succeeded
    case success(Data?)

    /// :nodoc:
    public var debugDescription: String {
        switch self {
        case let .failure(error):
            return "Data task failed with error: \(error)"
        case let .success(data):
            if let data = data {
                return "Data task succeeded with Data: \(String(describing: data))"
            } else {
                return "Data task succeeded with empty Data"
            }
        }
    }
}
