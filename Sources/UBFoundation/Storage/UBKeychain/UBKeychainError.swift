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

    var localizedDescription: String {
        switch self {
        case let .encodingError(error):
            return "encodingError: \(error.localizedDescription)"
        case let .decodingError(error):
            return "decodingError: \(error.localizedDescription)"
        case let .storingError(status):
            return "storingError OSStatus: \(status)"
        case .notFound:
            return "notFound"
        case let .cannotAccess(status):
            return "cannotAccess OSStatus: \(status)"
        case let .cannotDelete(status):
            return "cannotDelete OSStatus: \(status)"
        }
    }
}
