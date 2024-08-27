//
//  UBURLRequest.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// A URL load request that is independent of protocol or URL scheme.
public struct UBURLRequest: Equatable, Hashable, CustomReflectable, CustomStringConvertible, CustomDebugStringConvertible {
    // MARK: - Properties

    /// Underlaying data holder
    private var _request: URLRequest

    /// The HTTP request method.
    public var httpMethod: UBHTTPMethod? {
        get {
            guard let requestHTTPMethod = _request.httpMethod else {
                return nil
            }
            return UBHTTPMethod(rawValue: requestHTTPMethod)
        }
        set {
            _request.httpMethod = newValue?.rawValue
        }
    }

    /// The URL of the request.
    public var url: URL? {
        get {
            _request.url
        }
        set {
            _request.url = newValue
        }
    }

    /// The main document URL associated with this request.
    public var mainDocumentURL: URL? {
        get {
            _request.mainDocumentURL
        }
        set {
            _request.mainDocumentURL = newValue
        }
    }

    /// The timeout interval of the request.
    ///
    /// If during a connection attempt the request remains idle for longer than the timeout interval, the request is considered to have timed out. The default timeout interval is 60 seconds.
    public var timeoutInterval: TimeInterval {
        get {
            _request.timeoutInterval
        }
        set {
            _request.timeoutInterval = newValue
        }
    }

    /// A Boolean value indicating whether the request is allowed to use the built-in cellular radios to satisfy the request.
    public var allowsCellularAccess: Bool {
        get {
            _request.allowsCellularAccess
        }
        set {
            _request.allowsCellularAccess = newValue
        }
    }

    /// The service type associated with this request.
    public var networkServiceType: URLRequest.NetworkServiceType {
        get {
            _request.networkServiceType
        }
        set {
            _request.networkServiceType = newValue
        }
    }

    /// A URLRequest representation of the UBURLRequest
    public func getRequest() -> URLRequest {
        _request
    }

    // MARK: - Initializers

    /// Creates and initializes a URL request with the given URL, cache policy, and timeout interval.
    ///
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - method: The HTTP Method to use. Default to GET.
    ///   - timeoutInterval: The timeout interval for the request. The default is 60.0.
    public init(url: URL, method: UBHTTPMethod = .get, timeoutInterval: TimeInterval = 60.0) {
        self.init(request: URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeoutInterval))
        httpMethod = method
    }

    /// Initializes a UBURLRequest request from a URLRequest
    ///
    /// - Parameter request: The request to replicate
    public init(request: URLRequest) {
        _request = request
    }

    // MARK: - Managing the Body of the request

    /// The data sent as the message body of a request, such as for an HTTP POST request.
    public var httpBody: Data? {
        _request.httpBody
    }

    /// Clears the HTTP body
    public mutating func clearHTTPBody() {
        _request.httpBody = nil
        // According to Apple docs, the content-length is set automatically for us.
        // https://developer.apple.com/documentation/foundation/urlrequest/2011502-allhttpheaderfields
        setHTTPHeaderField(UBHTTPHeaderField(key: .contentType, value: nil))
    }

    /// Sets an HTTP body
    ///
    /// - Parameters:
    ///   - body: The body
    public mutating func setHTTPBody(_ body: UBURLRequestBody) {
        _request.httpBody = body.data
        // According to Apple docs, the content-length is set automatically for us.
        // https://developer.apple.com/documentation/foundation/urlrequest/2011502-allhttpheaderfields
        setHTTPHeaderField(UBHTTPHeaderField(key: .contentType, value: body.mimeType.stringValue))
    }

    /// Sets an HTTP body
    ///
    /// - Parameters:
    ///   - bodyProvider: The body provider
    /// - Throws: Rethrow the error throws by the request body provider
    public mutating func setHTTPBody(_ bodyProvider: URLRequestBodyConvertible) throws {
        try setHTTPBody(bodyProvider.httpRequestBody())
    }

    /// Sets a JSON body
    ///
    /// - Parameters:
    ///   - object: The object to encode
    ///   - encoder: The encoder
    /// - Throws: incase the ecoder could not encode
    public mutating func setHTTPJSONBody(_ object: some Encodable, encoder: JSONEncoder = JSONEncoder()) throws {
        let body = try UBURLRequestBody(data: encoder.encode(object), mimeType: .json())
        setHTTPBody(body)
    }

    // MARK: - Managing the Headers of the request

    /// A dictionary containing all the request’s HTTP header fields.
    public var allHTTPHeaderFields: [String: String]? {
        _request.allHTTPHeaderFields
    }

    /// Sets a value for a header field.
    ///
    /// - Parameter field: The new value for the header field.
    public mutating func setHTTPHeaderField(_ field: UBHTTPHeaderField) {
        _request.setValue(field.value, forHTTPHeaderField: field.key)
    }

    /// Adds one value to the header field.
    ///
    /// - Parameter field: The value for the header field.
    public mutating func addToHTTPHeaderField(_ field: UBHTTPHeaderField) {
        guard let value = field.value else {
            return
        }
        _request.addValue(value, forHTTPHeaderField: field.key)
    }

    /// Retrieves a header value.
    ///
    /// Note that, in keeping with the HTTP RFC, HTTP header field names are case-insensitive.
    ///
    /// - Parameter field: The header field name to use for the lookup (case-insensitive).
    /// - Returns: The value associated with the header field field, or nil if there is no corresponding header field.
    public func value(forHTTPHeaderField field: String) -> String? {
        _request.value(forHTTPHeaderField: field)
    }

    // MARK: - URL Parameter

    /// Sets the query parameters
    ///
    /// - Parameter parameters: A dictionary containing the query parameters
    /// - Throws: `UBNetworkingError` in case of missing or malformed URL
    public mutating func setQueryParameters(_ parameters: [String: String?]) throws {
        try setQueryParameters(parameters.map { URLQueryItem(name: $0.key, value: $0.value) }, percentEncoded: false)
    }

    /// Sets the query parameters
    ///
    /// - Parameter parameters: A dictionary containing the percent encoded query parameters
    /// - Throws: `UBNetworkingError` in case of missing or malformed URL
    @available(iOS 11.0, *)
    public mutating func setPercentEncodedQueryParameters(_ parameters: [String: String?]) throws {
        try setQueryParameters(parameters.map { URLQueryItem(name: $0.key, value: $0.value) }, percentEncoded: true)
    }

    /// Deprecated because of spelling issue, will be removed in next major release.
    /// Please use `setQueryParameter:`
    @available(swift, deprecated: 1.0, renamed: "setQueryParameter()")
    public mutating func setQueryParameters(_ parameter: URLQueryItem) throws {
        try setQueryParameters([parameter], percentEncoded: false)
    }

    /// Sets the query parameter
    ///
    /// - Parameter parameter: A query item
    /// - Throws: `UBNetworkingError` in case of missing or malformed URL
    public mutating func setQueryParameter(_ parameter: URLQueryItem) throws {
        try setQueryParameters([parameter], percentEncoded: false)
    }

    /// Sets the query parameter
    ///
    /// - Parameter parameter: A percent encoded query item
    /// - Throws: `UBNetworkingError` in case of missing or malformed URL
    @available(iOS 11.0, *)
    public mutating func setPercentEncodedQueryParameter(_ parameter: URLQueryItem) throws {
        try setQueryParameters([parameter], percentEncoded: true)
    }

    /// Sets the query parameters
    ///
    /// - Parameter parameters: An array containing the query parameters
    /// - Throws: `UBNetworkingError` in case of missing or malformed URL
    public mutating func setQueryParameters(_ parameters: [URLQueryItem]) throws {
        try setQueryParameters(parameters, percentEncoded: false)
    }

    /// Sets the query parameters
    ///
    /// - Parameter parameters: An array containing the percent encoded query parameters
    /// - Throws: `UBNetworkingError` in case of missing or malformed URL
    @available(iOS 11.0, *)
    public mutating func setPercentEncodedQueryParameters(_ parameters: [URLQueryItem]) throws {
        try setQueryParameters(parameters, percentEncoded: true)
    }

    private mutating func setQueryParameters(_ parameters: [URLQueryItem], percentEncoded: Bool) throws {
        guard let url else {
            throw UBInternalNetworkingError.missingURL
        }
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw UBInternalNetworkingError.malformedURL(url: url)
        }

        if percentEncoded {
            if #available(iOS 11.0, *) {
                urlComponents.percentEncodedQueryItems = parameters
            } else {
                assertionFailure("It's not possible to call percentEncodedQueryItems before iOS 11")
                urlComponents.queryItems = parameters
            }
        } else {
            urlComponents.queryItems = parameters
        }

        guard let newURL = urlComponents.url else {
            throw UBInternalNetworkingError.couldNotCreateURL
        }
        self.url = newURL
    }

    /// Get all query parameters
    ///
    /// - Returns: All query parameters
    /// - Throws: `UBNetworkingError` in case of missing or malformed URL
    public func allQueryParameters() throws -> [URLQueryItem] {
        guard let url else {
            throw UBInternalNetworkingError.missingURL
        }
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw UBInternalNetworkingError.malformedURL(url: url)
        }
        return urlComponents.queryItems ?? []
    }

    // MARK: - Other methods

    /// A textual description of the request.
    public var description: String {
        _request.description
    }

    /// A textual description of the request suitable for debugging.
    public var debugDescription: String {
        let headers = String(describing: _request.allHTTPHeaderFields ?? [:])

        let body = _request.httpBody != nil ? String(data: _request.httpBody!, encoding: .utf8) ?? "<Unparsable to UTF-8 Data>" : "<No Body>"
        return _request.debugDescription + "\nHeader: " + headers + "\nBody: " + body
    }

    /// A mirror that reflects the request.
    public var customMirror: Mirror {
        _request.customMirror
    }
}
