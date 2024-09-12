//
//  UBKeychainError.swift
//
//
//  Created by Stefan Mitterrutzner on 08.12.21.
//

import Foundation

/// Keychain Errors
public enum UBKeychainError: Error {
    /// Object could not be encoded
    case encodingError(_ error: Error)
    /// Object could not be decoded
    case decodingError(_ error: Error)
    /// A error happend while storing the object
    case storingError(_ status: OSStatus)
    /// The object was not found
    case notFound
    /// a Access error happend
    case cannotAccess(_ status: OSStatus)
    /// a deletion error happend
    case cannotDelete(_ status: OSStatus)
    /// This error should never happen
    case keychainNotReturningData

    var localizedDescription: String {
        switch self {
            case let .encodingError(error):
                "encodingError: \(error.localizedDescription)"
            case let .decodingError(error):
                "decodingError: \(error.localizedDescription)"
            case let .storingError(status):
                "storingError OSStatus: \(status)"
            case .notFound:
                "notFound"
            case let .cannotAccess(status):
                "cannotAccess OSStatus: \(status)"
            case let .cannotDelete(status):
                "cannotDelete OSStatus: \(status)"
            case .keychainNotReturningData:
                "not returning data"
        }
    }
}
