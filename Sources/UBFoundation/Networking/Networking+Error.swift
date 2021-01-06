//
//  Networking+Error.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// Networking errors
public enum UBNetworkingError: Error, Equatable {
    /// An unexpected error means that something extraordinary happened
    case unexpected
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
    /// The certificate validation process failed
    case certificateValidationFailed
    /// The request has failed with a status code
    case requestFailed(httpStatusCode: Int)
    /// The request got redirected
    case requestRedirected
    /// No cached data was found
    case noCachedData
    /// Synchronous task timed out
    case timedOut
    /// Canceled request
    case canceled
}

/// A structure that encapsulate the error body returned from the backend
public protocol UBURLDataTaskErrorBody: Error {
    /// The base error that was initially generated and passed up the stack
    var baseError: Error? { get set }
}

// MARK: - Connectivity

extension Error {

    public var ub_isNotConnectedError: Bool {
        if let error = self as? NSError, error.domain == NSURLErrorDomain, error.code == NSURLErrorNotConnectedToInternet {
            return true
        } else {
            return false
        }
    }
}

// MARK: - UBCodedError

extension UBNetworkingError: UBCodedError {
    static let prefix = "[NE]"
    public var errorCode: String {
        switch self {
        case .certificateValidationFailed: return Self.prefix + "CVF"
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
        case .timedOut: return Self.prefix + "TIMEDOUT"
        case .unexpected: return Self.prefix + "UNEXP"
        case .canceled: return Self.prefix + "CANCELLED"
        }
    }
}
