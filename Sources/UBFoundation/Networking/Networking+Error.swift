//
//  Networking+Error.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// Networking errors
public enum UBNetworkingError: LocalizedError, Equatable {
    /// Not connected to the internet (e.g., airplane mode, data not allowed)
    case notConnected(NSError)
    /// The connection timed out
    case timedOut(NSError? = nil)
    /// The certificate validation process failed
    case certificateValidationFailed(NSError? = nil)
    /// We cannot provide actionable information to the user. It is likely that something is broken on our end
    case `internal`(UBInternalNetworkingError)
}

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
    /// Other error
    case otherError(NSError)
}

/// A structure that encapsulate the error body returned from the backend
public protocol UBURLDataTaskErrorBody: Error {
    /// The base error that was initially generated and passed up the stack
    var baseError: Error? { get set }
}

public extension UBNetworkingError {
    init(_ error: Error) {
        switch error {
            case let error as UBNetworkingError:
                self = error
            case let error as UBInternalNetworkingError:
                self = UBNetworkingError.internal(error)
            case let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet:
                self = .notConnected(error)
            case let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorDataNotAllowed:
                self = .notConnected(error)
            case let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut:
                self = .timedOut(error)
            case let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorServerCertificateUntrusted:
                self = .certificateValidationFailed(error)
            case let error as UBNetworkTaskRecoveryOptions:
                self = UBNetworkingError.internal(.recoverableError(error))
            case let error as NSError:
                let otherError = UBInternalNetworkingError.otherError(error)
                self = .internal(otherError)
        }
    }
}

// MARK: - UBCodedError

private let errorCodePrefix = "[NE]"

extension UBNetworkingError: UBCodedError {
    public var errorCode: String {
        let code: String = {
            switch self {
                case let .notConnected(error):
                    return "[NOCONN]\(error.errorCode)"
                case let .timedOut(error):
                    if let err = error {
                        return "[TMOUT]\(err.errorCode)"
                    } else {
                        return "[TMOUT]"
                    }
                case let .certificateValidationFailed(error):
                    if let err = error {
                        return "[CVF]\(err.errorCode)"
                    } else {
                        return "[CVF]"
                    }
                case let .internal(error):
                    return "\(error.errorCode)"
            }
        }()
        return "\(errorCodePrefix)\(code)"
    }
}

extension UBNetworkingError {
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return NSLocalizedString("error_timeout", bundle: Bundle.module, comment: "Connection to the server failed")
        case .timedOut:
            return NSLocalizedString("error_timeout", bundle: Bundle.module, comment: "The request timed out")
        case .certificateValidationFailed: 
            return NSLocalizedString("error_invalid_certificate_message", bundle: Bundle.module, comment: "Validation of TLS certificate failed")
        default: 
            return NSLocalizedString("error_unexpected", bundle: Bundle.module, comment: "Generic unexpected error message")
        }
    }

    public var localizedDescription: String {
        var errorMessage = NSLocalizedString("error_unexpected", bundle: Bundle.module, comment: "Generic unexpected error message")
        if let description = errorDescription {
            errorMessage = description
        }
        let errorCodePrefix = NSLocalizedString("error_code_prefix", bundle: Bundle.module, comment: "Prefix of error code")
        
        return "\(errorMessage)\n\n\(errorCodePrefix) \(errorCode)"
    }
}

extension UBInternalNetworkingError: UBCodedError {
    public var errorCode: String {
        let code: String = {
            switch self {
                case .couldNotCreateURL: return "[CNCU]"
                case .couldNotDecodeBody: return "[CNDB]"
                case .couldNotEncodeBody: return "[CNEB]"
                case .malformedURL: return "[MALURL]"
                case .missingURL: return "[MIURL]"
                case .noCachedData: return "[NOCACHE]"
                case .notHTTPResponse: return "[NOHTTPR]"
                case let .requestFailed(httpStatusCode: status): return "[RF-\(status)]"
                case .requestRedirected: return "[RR]"
                case .responseBodyIsEmpty: return "[RBIE]"
                case .responseBodyIsNotEmpty: return "[RBINE]"
                case .responseMIMETypeValidationFailed: return "[RMIMETVF]"
                case let .responseStatusValidationFailed(status: status): return "[RSVF-\(status)]"
                case .unwrapError: return "[UNWRP]"
                case .synchronousTimedOut: return "[SEMTIMEOUT]"
                case .canceled: return "[CANCELLED]"
                case .recoverableError: return "[REC]"
                case let .otherError(error): return error.errorCode
            }
        }()
        return code
    }
}
