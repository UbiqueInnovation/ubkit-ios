//
//  HTTPHeaderField.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

// Standard: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers

/// An HTTP request header field
public struct HTTPHeaderField {
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

    /// Initializes a custom request header field
    ///
    /// - Parameters:
    ///   - key: The key of the field
    ///   - value: The value of the field. `Nil` to remove the field
    public init(key: StandardKeys, value: String?) {
        self.key = key.rawValue
        self.value = value
    }

    /// Initializes a custom request header field
    ///
    /// - Parameters:
    ///   - key: The key of the field
    ///   - value: The value of the field. `Nil` to remove the field
    public init(key: StandardKeys, value: MIMEType) {
        self.key = key.rawValue
        self.value = value.stringValue
    }
}

// MARK: - Standard Header Keys

extension HTTPHeaderField {
    /// Standard Header Fields
    public enum StandardKeys: String {
        /// Accept header field key
        case accept = "Accept"
        /// Accept Encoding header field key
        case acceptEncoding = "Accept-Encoding"
        /// Accept Language header field key
        case acceptLanguage = "Accept-Language"
        /// Age header field key
        case age = "Age"
        /// Authorization header field key
        case authorization = "Authorization"
        /// Cache Control header field key
        case cacheControl = "Cache-Control"
        /// Content Disposition header field key
        case contentDisposition = "Content-Disposition"
        /// Content Encoding header field key
        case contentEncoding = "Content-Encoding"
        /// Content Language header field key
        case contentLanguage = "Content-Language"
        /// Content Length header field key
        case contentLength = "Content-Length"
        /// Content MD5 header field key
        case contentMD5 = "Content-MD5"
        /// Content Type header field key
        case contentType = "Content-Type"
        /// Date header field key
        case date = "Date"
        /// A unique string identifying the version of the resource.
        case etag = "ETag"
        /// Expires header field key
        case expires = "Expires"
        /// Applies the method only if the stored resource doesn't match any of the given ETags
        case ifNoneMatch = "If-None-Match"
        /// Expects the entity to be transmitted only if it has been modified after the given date
        case ifModifiedSince = "If-Modified-Since"
        /// Last Modified header field key
        case lastModified = "Last-Modified"
        /// User Agent header field key
        case userAgent = "User-Agent"
    }
}
