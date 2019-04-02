//
//  UBURLRequest+Body.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// An encapsulation of a HTTP request body
public struct UBURLRequestBody {
    /// The data of the body
    public let data: Data
    /// The mime type of the body
    public let mimeType: MIMEType

    /// Initializes a request body
    ///
    /// - Parameters:
    ///   - data: The data of the body
    ///   - mimeType: The mime type of the body
    public init(data: Data, mimeType: MIMEType) {
        self.data = data
        self.mimeType = mimeType
    }
}
