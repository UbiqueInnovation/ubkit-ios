//
//  Result.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// A generic result element
public enum Result<T>: CustomDebugStringConvertible {
    /// Failure result with an error
    case failure(Error)
    /// Successful result with payload
    case success(T)

    /// :nodoc:
    public var debugDescription: String {
        switch self {
        case let .failure(error):
            return "Failure with error: \(error)"
        case let .success(data):
            return "Success with \(T.self): \(String(describing: data))"
        }
    }
}

/// A generic result element
public enum VoidResult: CustomDebugStringConvertible {
    /// Failure result with an error
    case failure(Error)
    /// Successful result
    case success

    /// :nodoc:
    public var debugDescription: String {
        switch self {
        case let .failure(error):
            return "Failure with error: \(error)"
        case .success:
            return "Success"
        }
    }
}
