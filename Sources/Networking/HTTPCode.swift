//
//  HTTPCode.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

// MARK: - HTTP code integer

extension Int {
    /// Get the http category
    var httpCodeCategory: HTTPCodeCategory {
        return HTTPCodeCategory(code: self)
    }

    /// Get the standard http code
    var standardHTTPCode: StandardHTTPCode? {
        return StandardHTTPCode(rawValue: self)
    }
}

/// A cluster of HTTP code
public enum HTTPCodeCategory {
    /// Code is outside of the known ranges
    case uncategorized
    /// Informational status
    case informational
    /// Success status
    case success
    /// Redirection status
    case redirection
    /// Client Error Status
    case clientError
    /// Server Error Status
    case serverError

    /// Initializes an HTTP code category
    ///
    /// - Parameter code: The HTTP code
    public init(code: Int) {
        switch code {
        case 100 ..< 200:
            self = .informational
        case 200 ..< 300:
            self = .success
        case 300 ..< 400:
            self = .redirection
        case 400 ..< 500:
            self = .clientError
        case 500 ..< 600:
            self = .serverError
        default:
            self = .uncategorized
        }
    }
}

/// The standard HTTP codes
public enum StandardHTTPCode: Int {

    // MARK: - 2xx Success

    /// The request has succeeded.
    case OK = 200
    /// The request has been fulfilled and resulted in a new resource being created.
    case created = 201
    /// The server has fulfilled the request but does not need to return an entity-body, and might want to return updated metainformation.
    case noContent = 204

    // MARK: - 3xx Redirection

    /// If the client has performed a conditional GET request and access is allowed, but the document has not been modified.
    case notModified = 304

    // MARK: - 4xx Client Error

    /// The request could not be understood by the server due to malformed syntax.
    case badRequest = 400
    /// The request requires user authentication.
    case unauthorized = 401
    /// The server understood the request, but is refusing to fulfill it. Authorization will not help and the request SHOULD NOT be repeated.
    case forbidden = 403
    /// The server has not found anything matching the Request-URI.
    case notFound = 404
    /// The request could not be completed due to a conflict with the current state of the resource.
    case conflict = 409

    // MARK: - 5xx Server Error

    /// The server encountered an unexpected condition which prevented it from fulfilling the request.
    case internalServerError = 500
    /// The server does not support the functionality required to fulfill the request.
    case notImplemented = 501
    /// The server, while acting as a gateway or proxy, received an invalid response from the upstream server it accessed in attempting to fulfill the request.
    case badGateway = 502
    /// The server is currently unable to handle the request due to a temporary overloading or maintenance of the server.
    case serviceNotAvailable = 503
}
