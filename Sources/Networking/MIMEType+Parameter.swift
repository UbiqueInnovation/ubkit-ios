//
//  MIMEType+Parameter.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 22.03.19.
//

import Foundation

// MARK: - Parameter

extension MIMEType {
    /// MIME Parameter
    /// - seeAlso: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
    public struct Parameter: Equatable {
        /// the separator used between type and parameter
        public static let typeParameterSeparator = ";"
        /// The separator for the key and value in a Parameter
        public static let keyValueSeparator = "="

        /// The key of the parameter
        let key: String
        /// The value of the parameter
        let value: String

        /// Initializes the parameter
        ///
        /// - Parameters:
        ///   - key: The key of the parameter
        ///   - value: The value of the parameter
        public init(key: String, value: String) {
            self.key = key.trimmingCharacters(in: .whitespaces).lowercased()
            self.value = value.trimmingCharacters(in: .whitespaces)
        }

        /// Initializes the paramter from a string
        ///
        /// - Parameter string: The string to parse
        public init?(string: String) {
            let desc = string.trimmingCharacters(in: .whitespaces)
            let parameterRegex = try! NSRegularExpression(pattern: "\(MIMEType.Parameter.typeParameterSeparator)\\s*([a-z]+)\(MIMEType.Parameter.keyValueSeparator)([a-z0-9\\p{Pd}]+)$", options: .caseInsensitive)

            guard let parameterResult = parameterRegex.firstMatch(in: desc, range: NSRange(desc.startIndex..., in: desc)) else {
                return nil
            }

            guard parameterResult.numberOfRanges == 3,
                let keyCapturedRange = Range(parameterResult.range(at: 1), in: desc),
                let valueCapturedRange = Range(parameterResult.range(at: 2), in: desc) else {
                return nil
            }

            let key = String(desc[keyCapturedRange])
            let value = String(desc[valueCapturedRange])

            self.init(key: key, value: value)
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

        /// Returns the string representation of the paramter
        public var stringValue: String {
            return MIMEType.Parameter.typeParameterSeparator + " " + key + MIMEType.Parameter.keyValueSeparator + value
        }
    }
}
