//
//  MIMEType+Parameter.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 22.03.19.
//

import Foundation

// MARK: - Parameter

public extension UBMIMEType {
    /// MIME Parameter
    /// - seeAlso: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
    struct Parameter: Equatable {
        /// The key of the parameter
        public let key: String
        /// The value of the parameter
        public let value: String

        /// Initializes the parameter
        ///
        /// - Parameters:
        ///   - key: The key of the parameter
        ///   - value: The value of the parameter
        public init(key: String, value: String) {
            self.key = key.trimmingCharacters(in: .whitespaces).lowercased()
            self.value = value.trimmingCharacters(in: .whitespaces)
        }

        /// Initializes the parameter for a charset dictated by an encoding
        ///
        /// - Parameter encoding: The encoding to parse
        public init?(charsetForEncoding encoding: String.Encoding) {
            if let charset = encoding.charsetName {
                self.init(key: "charset", value: charset)
            } else {
                return nil
            }
        }
    }
}
