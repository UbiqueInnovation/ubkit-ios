//
//  HTTPURLRequest.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// A URL load request that is independent of protocol or URL scheme.
public struct HTTPURLRequest: Equatable, Hashable, CustomReflectable, CustomStringConvertible, CustomDebugStringConvertible {
    /// Underlaying data holder
    private var request: URLRequest

    /// Creates and initializes a URL request with the given URL, cache policy, and timeout interval.
    ///
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - cachePolicy: The cache policy for the request. The default is `NSURLRequest.CachePolicy.useProtocolCachePolicy`.
    ///   - timeoutInterval: The timeout interval for the request. The default is 60.0.
    public init(url: URL, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 60.0) {
        request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
    }

    /// The request’s cache policy.
    public var cachePolicy: URLRequest.CachePolicy {
        get {
            return request.cachePolicy
        }
        set {
            request.cachePolicy = newValue
        }
    }

    /// The HTTP request method.
    public var httpMethod: HTTPMethod? {
        get {
            guard let requestHTTPMethod = request.httpMethod else {
                return nil
            }
            return HTTPMethod(rawValue: requestHTTPMethod)
        }
        set {
            request.httpMethod = newValue?.rawValue
        }
    }

    /// The URL of the request.
    public var url: URL? {
        get {
            return request.url
        }
        set {
            request.url = newValue
        }
    }

    /// The data sent as the message body of a request, such as for an HTTP POST request.
    public var httpBody: Data? {
        return request.httpBody
    }

    /// Clears the HTTP body
    public mutating func clearHTTPBody() {
        request.httpBody = nil
        // According to Apple docs, the content-length is set automatically for us.
        // https://developer.apple.com/documentation/foundation/urlrequest/2011502-allhttpheaderfields
        setHTTPHeaderField(HTTPRequestHeaderField(contentType: nil))
    }

    /// Sets an HTTP body
    ///
    /// - Parameters:
    ///   - bodyProvider: The body provider
    /// - Throws: Rethrow the error throws by the request body provider
    public mutating func setHTTPBody(_ bodyProvider: HTTPRequestBodyProvider) throws {
        let body = try bodyProvider.httpRequestBody()
        request.httpBody = body.data
        // According to Apple docs, the content-length is set automatically for us.
        // https://developer.apple.com/documentation/foundation/urlrequest/2011502-allhttpheaderfields
        setHTTPHeaderField(HTTPRequestHeaderField(contentType: body.mimeType.description))
    }

    /// A dictionary containing all the request’s HTTP header fields.
    public var allHTTPHeaderFields: [String: String]? {
        return request.allHTTPHeaderFields
    }

    /// Sets a value for a header field.
    ///
    /// - Parameter field: The new value for the header field.
    public mutating func setHTTPHeaderField(_ field: HTTPRequestHeaderField) {
        request.setValue(field.value, forHTTPHeaderField: field.key)
    }

    /// Adds one value to the header field.
    ///
    /// - Parameter field: The value for the header field.
    public mutating func addToHTTPHeaderField(_ field: HTTPRequestHeaderField) {
        guard let value = field.value else {
            return
        }
        request.addValue(value, forHTTPHeaderField: field.key)
    }

    /// Retrieves a header value.
    ///
    /// Note that, in keeping with the HTTP RFC, HTTP header field names are case-insensitive.
    ///
    /// - Parameter field: The header field name to use for the lookup (case-insensitive).
    /// - Returns: The value associated with the header field field, or nil if there is no corresponding header field.
    public func value(forHTTPHeaderField field: String) -> String? {
        return request.value(forHTTPHeaderField: field)
    }

    /// The timeout interval of the request.
    ///
    /// If during a connection attempt the request remains idle for longer than the timeout interval, the request is considered to have timed out. The default timeout interval is 60 seconds.
    public var timeoutInterval: TimeInterval {
        get {
            return request.timeoutInterval
        }
        set {
            request.timeoutInterval = newValue
        }
    }

    /// A Boolean value indicating whether the request is allowed to use the built-in cellular radios to satisfy the request.
    public var allowsCellularAccess: Bool {
        get {
            return request.allowsCellularAccess
        }
        set {
            request.allowsCellularAccess = newValue
        }
    }

    /// The service type associated with this request.
    public var networkServiceType: URLRequest.NetworkServiceType {
        get {
            return request.networkServiceType
        }
        set {
            request.networkServiceType = newValue
        }
    }

    /// A textual description of the request.
    public var description: String {
        return request.description
    }

    /// A textual description of the request suitable for debugging.
    public var debugDescription: String {
        return request.debugDescription
    }

    /// A mirror that reflects the request.
    public var customMirror: Mirror {
        return request.customMirror
    }
}
