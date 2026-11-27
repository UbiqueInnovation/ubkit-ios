//
//  UBSecureStorageError.swift
//
//
//  Created by Stefan Mitterrutzner on 07.06.22.
//

import Foundation

public enum UBSecureStorageError: Error {
    case enclaveError(UBCodedError)
    case ioError(Error)
    case decodingError(_ error: Error)
    case encodingError(_ error: Error)
    case notFound
}

extension UBSecureStorageError: UBCodedError {
    static let prefix = "[US]"
    public var errorCode: String {
        switch self {
            case let .enclaveError(err):
                return Self.prefix + err.errorCode
            case let .ioError(err):
                return Self.prefix + "IO\((err as NSError).code)"
            case let .decodingError(err):
                return Self.prefix + "DE\((err as NSError).code)"
            case let .encodingError(err):
                return Self.prefix + "EN\((err as NSError).code)"
            case .notFound:
                return Self.prefix + "NF"
        }
    }
}
