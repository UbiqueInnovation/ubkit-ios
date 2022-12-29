//
//  UBURLRequest+Body.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

/// An encapsulation of a HTTP request body
public struct UBURLRequestBody {
    /// The data of the body
    public let data: Data
    /// The mime type of the body
    public let mimeType: UBMIMEType

    /// Initializes a request body
    ///
    /// - Parameters:
    ///   - data: The data of the body
    ///   - mimeType: The mime type of the body
    public init(data: Data, mimeType: UBMIMEType) {
        self.data = data
        self.mimeType = mimeType
    }
}
#endif
