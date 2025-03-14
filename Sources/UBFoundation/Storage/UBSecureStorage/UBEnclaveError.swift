//
//  UBEnclaveError.swift
//
//
//  Created by Stefan Mitterrutzner on 07.06.22.
//

import Foundation

public enum UBEnclaveError: Error {
    case algNotSupported

    case pubkeyIrretrievable

    case secError(_: Error)

    case keyLoadingError(_: OSStatus)
}

extension UBEnclaveError: UBCodedError {
    static let prefix = "[UEE]"
    public var errorCode: String {
        switch self {
            case .algNotSupported:
                return Self.prefix + "ANS"
            case .pubkeyIrretrievable:
                return Self.prefix + "PKI"
            case let .secError(err):
                return Self.prefix + "SE\((err as NSError).code)"
            case let .keyLoadingError(status):
                return Self.prefix + "KLE\(status)"
        }
    }
}
