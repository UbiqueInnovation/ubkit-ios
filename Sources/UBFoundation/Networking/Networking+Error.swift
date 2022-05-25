//
//  Networking+Error.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// Networking errors
public enum UBNetworkingError: LocalizedError {
    /// Not connected to the internet (e.g., airplane mode, data not allowed)
    case notConnected
    /// The connection timed out
    case timedOut
    /// The certificate validation process failed
    case certificateValidationFailed
    /// We cannot provide actionable information to the user. It is likely that something is broken on our end
    case `internal`(UBInternalNetworkingError)
    /// decoded error using custom error decoder
    case decoded(Error)
}

public protocol EquatableError: Error, Equatable { }

public enum UBInternalNetworkingError: LocalizedError, Equatable {
    /// The URL is missing in the request
    case missingURL
    /// The URL is malformed and cannot be interpretade
    case malformedURL(url: URL)
    /// The URL could not be created
    case couldNotCreateURL
    /// The body of the response could not be decoded
    case couldNotDecodeBody
    /// The body of the response could not be encoded
    case couldNotEncodeBody
    /// The status did not match
    case responseStatusValidationFailed(status: Int)
    /// The mime type did not match
    case responseMIMETypeValidationFailed
    /// The response received is not HTTP response
    case notHTTPResponse
    /// The response body is empty. Expected it to not be empty
    case responseBodyIsEmpty
    /// The response body is not empty. Expected it to be empty
    case responseBodyIsNotEmpty
    /// The request has failed with a status code
    case requestFailed(httpStatusCode: Int)
    /// The request got redirected
    case requestRedirected
    /// No cached data was found
    case noCachedData
    /// The synchronous task semaphore timed out
    case synchronousTimedOut
    /// Canceled request
    case canceled
    /// Recoverable error
    case recoverableError(UBNetworkTaskRecoveryOptions)
    /// Failed to unwrap an optional (should never happen)
    case unwrapError
    /// Other error from NSURLErrorDomain
    case otherNSURLError(NSError)
}

extension UBNetworkingError {
    init(_ error: Error) {
        switch error {
        case let error as UBNetworkingError:
            self = error
        case let error as UBInternalNetworkingError:
            self = UBNetworkingError.internal(error)
        case let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet:
            self = .notConnected
        case let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorDataNotAllowed:
            self = .notConnected
        case let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut:
            self = .timedOut
        case let error as UBNetworkTaskRecoveryOptions:
            self = UBNetworkingError.internal(.recoverableError(error))
        case let error as NSError:
            let otherError = UBInternalNetworkingError.otherNSURLError(error)
            self = .internal(otherError)
        }
    }
}

// MARK: - UBCodedError

private let errorCodePrefix = "[NE]"

extension UBNetworkingError: UBCodedError {
    public var errorCode: String {
        switch self {
        case .notConnected: return "\(errorCodePrefix)NOCONN"
        case .timedOut: return "\(errorCodePrefix)TIMEDOUT"
        case .certificateValidationFailed: return "\(errorCodePrefix)CVF"
        case let .decoded(error):
                if let error = error as? UBCodedError {
                    return "\(errorCodePrefix)DEC\(error.errorCode)"
                }
                else {
                    return "\(errorCodePrefix)DEC"
                }
        case let .internal(error): return error.errorCode
        }
    }
}

extension UBInternalNetworkingError: UBCodedError {
    public var errorCode: String {
        let postfix: String = {
            switch self {
            case .couldNotCreateURL: return "CNCU"
            case .couldNotDecodeBody: return "CNDB"
            case .couldNotEncodeBody: return "CNEB"
            case .malformedURL: return "MALURL"
            case .missingURL: return "MIURL"
            case .noCachedData: return "NOCACHE"
            case .notHTTPResponse: return "NOHTTPR"
            case let .requestFailed(httpStatusCode: status): return "RF\(status)"
            case .requestRedirected: return "RR"
            case .responseBodyIsEmpty: return "RBIE"
            case .responseBodyIsNotEmpty: return "RBINE"
            case .responseMIMETypeValidationFailed: return "RMIMETVF"
            case let .responseStatusValidationFailed(status: status): return "RSVF\(status)"
            case .unwrapError: return "UNWRP"
            case .synchronousTimedOut: return "SEMTIMEOUT"
            case .canceled: return "CANCELLED"
            case .recoverableError: return "REC"
            case let .otherNSURLError(error): return "NSURL \(error.code)"
            }
        }()
        return "\(errorCodePrefix)\(postfix)"
    }
}
