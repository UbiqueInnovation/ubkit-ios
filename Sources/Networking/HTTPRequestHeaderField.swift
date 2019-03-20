//
//  HTTPHeaderField.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// An HTTP request header field
public struct HTTPRequestHeaderField {
    /// The value of the fieald
    public let value: String?
    /// The key of the field
    public let key: String

    /// Initializes a custom request header field
    ///
    /// - Parameters:
    ///   - key: The key of the field
    ///   - value: The value of the field. `Nil` to remove the field
    public init(key: String, value: String?) {
        self.key = key
        self.value = value
    }

    /// Accept header field
    ///
    /// - Parameter value: The value of the field. `Nil` to remove the field
    public init(accept value: String?) {
        self.init(key: "Accept", value: value)
    }

    /// Accept Encoding header field
    ///
    /// - Parameter value: The value of the field. `Nil` to remove the field
    public init(acceptEncoding value: String?) {
        self.init(key: "Accept-Encoding", value: value)
    }

    /// Accept Language header field
    ///
    /// - Parameter value: The value of the field. `Nil` to remove the field
    public init(acceptLanguage value: String?) {
        self.init(key: "Accept-Language", value: value)
    }

    /// Authorization header field
    ///
    /// - Parameter value: The value of the field. `Nil` to remove the field
    public init(authorization value: String?) {
        self.init(key: "Authorization", value: value)
    }

    /// Cache control header field
    ///
    /// - Parameter value: The value of the field. `Nil` to remove the field
    public init(cacheControl value: String?) {
        self.init(key: "Cache-Control", value: value)
    }

    /// Content length header field
    ///
    /// - Parameter value: The value of the field. `Nil` to remove the field
    public init(contentLength value: String?) {
        self.init(key: "Content-Length", value: value)
    }
    
    /// Content type header field
    ///
    /// - Parameter value: The value of the field. `Nil` to remove the field
    public init(contentType value: String?) {
        self.init(key: "Content-Type", value: value)
    }

    /// User agent header field
    ///
    /// - Parameter value: The value of the field. `Nil` to remove the field
    public init(userAgent value: String?) {
        self.init(key: "User-Agent", value: value)
    }
}
