//
//  HTTPRequestBodyProvider.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// An encapsulation of a HTTP request body
public struct HTTPRequestBody {
    /// The data of the body
    let data: Data
    /// The mime type of the body
    let mimeType: HTTPMIMEType
}

/// Conforming to the protocol allows the conformant to be used as a Body in an HTTP request
public protocol HTTPRequestBodyProvider {
    /// get a body for the HTTP request
    ///
    /// - Returns: A body for the HTTP Request
    /// - Throws: An error in case the body cannot be formed
    func httpRequestBody() throws -> HTTPRequestBody
}

// MARK: - HTTPRequestBodyProvider

extension Data: HTTPRequestBodyProvider {
    /// :nodoc:
    public func httpRequestBody() throws -> HTTPRequestBody {
        return HTTPRequestBody(data: self, mimeType: .octetStream)
    }
}

extension String: HTTPRequestBodyProvider {
    /// :nodoc:
    public func httpRequestBody() throws -> HTTPRequestBody {
        // Extracting UTF-8 data from a string in Swift never fails as every string is represented in UTF 8.
        let data = self.data(using: .utf8)!
        return HTTPRequestBody(data: data, mimeType: .textPlain(charset: "utf-8"))
    }
}
