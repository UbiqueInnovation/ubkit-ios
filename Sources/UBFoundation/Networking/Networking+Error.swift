//
//  Networking+Error.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// Networking errors
public enum UBNetworkingError: LocalizedError, Equatable {
    /// Not connected to the internet
    case notConnected
    /// The connection timed out
    case timedOut
    /// The certificate validation process failed
    case certificateValidationFailed
    /// We cannot provide actionable information to the user. It is likely that something is broken on our end
    case unexpected(UBUnexpectedNetworkingError)
}

public enum UBUnexpectedNetworkingError: LocalizedError, Equatable {
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
    case semaphoreTimedOut
    /// Canceled request
    case canceled
    /// Recovery failed (should never happen)
    case recoveryFailed
    /// Failed to unwrap an optional (should never happen)
    case unwrapError
    /// Other error from NSURLErrorDomain
    case otherNSURLError(NSError)
}

/// A structure that encapsulate the error body returned from the backend
public protocol UBURLDataTaskErrorBody: Error {
    /// The base error that was initially generated and passed up the stack
    var baseError: Error? { get set }
}

extension UBNetworkingError {

    init(_ error: Error) {
        switch error {
        case let error as UBNetworkingError:
            self = error
        case let error as UBUnexpectedNetworkingError:
            self =  UBNetworkingError.unexpected(error)
        case let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet:
            self = .notConnected
        case let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut:
            self = .timedOut
        case _ as RecoverableError:
            self = UBNetworkingError.unexpected(.recoveryFailed)
        case let error as NSError:
            let otherError = UBUnexpectedNetworkingError.otherNSURLError(error)
            self = .unexpected(otherError)
        }
    }
}

// MARK: - UBCodedError

extension UBNetworkingError: UBCodedError {
    static let prefix = "[NE]"
    public var errorCode: String {
        switch self {
        case .notConnected: return Self.prefix + "NOCONN"
        case .timedOut: return Self.prefix + "TIMEDOUT"
        case .certificateValidationFailed: return Self.prefix + "CVF"
        case .unexpected(let error): return error.errorCode
        }
    }
}


extension UBUnexpectedNetworkingError: UBCodedError {
    static let prefix = "[NE]"
    public var errorCode: String {
        switch self {
        case .couldNotCreateURL: return Self.prefix + "CNCU"
        case .couldNotDecodeBody: return Self.prefix + "CNDB"
        case .couldNotEncodeBody: return Self.prefix + "CNEB"
        case .malformedURL: return Self.prefix + "MALURL"
        case .missingURL: return Self.prefix + "MIURL"
        case .noCachedData: return Self.prefix + "NOCACHE"
        case .notHTTPResponse: return Self.prefix + "NOHTTPR"
        case let .requestFailed(httpStatusCode: status): return Self.prefix + "RF\(status)"
        case .requestRedirected: return Self.prefix + "RR"
        case .responseBodyIsEmpty: return Self.prefix + "RBIE"
        case .responseBodyIsNotEmpty: return Self.prefix + "RBINE"
        case .responseMIMETypeValidationFailed: return Self.prefix + "RMIMETVF"
        case let .responseStatusValidationFailed(status: status): return Self.prefix + "RSVF\(status)"
        case .unwrapError: return Self.prefix + "UNWRP"
        case .semaphoreTimedOut: return Self.prefix + "SEMTIMEOUT"
        case .canceled: return Self.prefix + "CANCELLED"
        case .recoveryFailed: return Self.prefix + "RECF"
        case .otherNSURLError(let error): return Self.prefix + "NSURL \(error.code)"
        }
    }
}
