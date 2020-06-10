//
//  HTTPMutableURLResponse.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 25.03.20.
//

import Foundation

/// A mutable version of a `HTTPURLResponse`
class HTTPMutableURLResponse {
    /// The URL for the response.
    var url: URL?
    /// The response’s HTTP status code.
    var statusCode: Int?
    /// The version of the HTTP response as returned by the server.
    var httpVersion: String?
    /// A dictionary representing the keys and values from the server’s response header.
    var allHeaderFields: [String: String]

    /// Initialize an empty mutable response
    init() {
        url = nil
        statusCode = nil
        httpVersion = nil
        allHeaderFields = [:]
    }

    /// Initialize the mutable response with an already present response
    /// - Parameters:
    ///   - response: The base response
    ///   - HTTPVersion: The HTTP Version of the server
    init?(_ response: HTTPURLResponse, httpVersion HTTPVersion: String? = "HTTP/1.1") {
        guard let url = response.url, let allHeaderFields = response.allHeaderFields as? [String: String] else {
            return nil
        }
        self.url = url
        statusCode = response.statusCode
        httpVersion = HTTPVersion
        self.allHeaderFields = allHeaderFields
    }

    /// Convert to a HTTPURLResponse
    var urlResponse: HTTPURLResponse? {
        guard let url = self.url, let statusCode = self.statusCode else {
            return nil
        }
        return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: allHeaderFields)
    }

    /// Returns the header field for the key
    ///
    /// - Parameter key: A standard key
    /// - Returns: The value associated with the key
    public func getHeaderField(key: UBHTTPHeaderField.StandardKeys) -> String? {
        return allHeaderFields[key.rawValue]
    }

    /// Set the header field value for the key
    ///
    /// - Parameter key: A standard key
    /// - Parameter value: A value to set
    /// - Returns: The value associated with the key
    public func setHeaderField(value: String, key: UBHTTPHeaderField.StandardKeys) {
        return allHeaderFields[key.rawValue] = value
    }

    /// Remove a header field
    /// - Parameter key: A standard key
    public func removeHeaderField(key: UBHTTPHeaderField.StandardKeys) {
        allHeaderFields.removeValue(forKey: key.rawValue)
    }
}

extension HTTPURLResponse {
    /// Create a mutable response
    var mutableResponse: HTTPMutableURLResponse? {
        HTTPMutableURLResponse(self)
    }
}