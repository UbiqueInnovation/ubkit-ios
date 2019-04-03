//
//  HTTPCode+Standard.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// The standard HTTP codes
public enum StandardHTTPCode: Int {

    // MARK: - 1xx Informational

    /// The client SHOULD continue with its request.
    case `continue` = 100

    // MARK: - 2xx Success

    /// The request has succeeded.
    case ok = 200
    /// The request has been fulfilled and resulted in a new resource being created.
    case created = 201
    /// The request has been accepted for processing, but the processing has not been completed.
    case accepted = 202
    /// The server has fulfilled the request but does not need to return an entity-body, and might want to return updated metainformation.
    case noContent = 204

    // MARK: - 3xx Redirection

    /// The requested resource has been assigned a new permanent URI and any future references to this resource SHOULD use one of the returned URIs
    case movedPermanently = 301
    /// Tells the client to look at (browse to) another URL
    case found = 302
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
    /// The server, while acting as a gateway or proxy, did not receive a timely response from the upstream server.
    case gatewayTimeout = 504
    /// The policy for accessing the resource has not been met in the request. The server should send back all the information necessary for the client to issue an extended request.
    case notExtended = 510
}
