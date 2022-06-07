//
//  UBSecureStorageError.swift
//  
//
//  Created by Stefan Mitterrutzner on 07.06.22.
//

import Foundation

public enum UBSecureStorageError: Error {
    case enclaveError(UBEnclaveError)
    case ioError(Error)
    case decodingError(_ error: Error)
    case encodingError(_ error: Error)
    case dataIntegrity
    case notFound
}

extension UBSecureStorageError: UBCodedError {
    static let prefix = "[US]"
    public var errorCode: String {
        switch self {
        case .enclaveError(let err):
            return Self.prefix + err.errorCode
        case .ioError(let err):
            return Self.prefix + "IO\((err as NSError).code)"
        case .decodingError(let err):
            return Self.prefix + "DE\((err as NSError).code)"
        case .encodingError(let err):
            return Self.prefix + "EN\((err as NSError).code)"
        case .dataIntegrity:
            return Self.prefix + "DIE"
        case .notFound:
            return Self.prefix + "NF"

        }
    }
}
