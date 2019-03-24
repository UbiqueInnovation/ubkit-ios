//
//  HTTPRequestBody+Convertible.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 24.03.19.
//

import Foundation

/// Conforming to the protocol allows the conformant to be used as a Body in an HTTP request
public protocol HTTPRequestBodyConvertible {
    /// get a body for the HTTP request
    ///
    /// - Returns: A body for the HTTP Request
    /// - Throws: An error in case the body cannot be formed
    func httpRequestBody() throws -> HTTPRequestBody
}

// MARK: - HTTPRequestBodyConvertible

extension Data: HTTPRequestBodyConvertible {
    /// :nodoc:
    public func httpRequestBody() throws -> HTTPRequestBody {
        return HTTPRequestBody(data: self, mimeType: .binary)
    }
}

extension String: HTTPRequestBodyConvertible {
    /// :nodoc:
    public func httpRequestBody() throws -> HTTPRequestBody {
        // Extracting UTF-8 data from a string in Swift never fails as every string is represented in UTF 8.
        let data = self.data(using: .utf8)!
        return HTTPRequestBody(data: data, mimeType: .text(encoding: .utf8))
    }
}

/// A URL Encoder. The keys are sorted aphabetically and it is case sensitive
public struct HTTPRequestBodyURLEncoder: HTTPRequestBodyConvertible {

    // MARK: - Properties

    /// The payload to encode
    public var payload: [String: String?]
    /// The encoding to use
    public var encoding: String.Encoding
    /// Check if we send the encoding in the mime type as a charset
    public var sendEncoding: Bool

    /// Initializes a URL encoder
    ///
    /// - Parameters:
    ///   - payload: The payload to encode
    ///   - encoding: The encoding to use
    ///   - sendEncoding: Check if we send the encoding in the mime type as a charset
    public init(payload: [String: String?], encoding: String.Encoding = .utf8, sendEncoding: Bool = false) {
        self.payload = payload
        self.encoding = encoding
        self.sendEncoding = sendEncoding
    }

    /// :nodoc:
    public func httpRequestBody() throws -> HTTPRequestBody {
        var urlComponents = URLComponents()
        urlComponents.queryItems = payload.sorted(by: { (left, right) -> Bool in
            left.key < right.key
        }).map({ URLQueryItem(name: $0, value: $1) })
        guard let query = urlComponents.query, let data = query.data(using: encoding) else {
            throw NetworkingError.couldNotEncodeBody
        }
        var mime: MIMEType = .formUrlencoded
        if sendEncoding {
            mime.parameter = MIMEType.Parameter(charsetForEncoding: encoding)
        }
        return HTTPRequestBody(data: data, mimeType: mime)
    }
}
