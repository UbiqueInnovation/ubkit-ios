//
//  HTTPMIMEType.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// An HTTP MIME type
/// See the standard at: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
public struct HTTPMIMEType: CustomStringConvertible {
    /// The type of the MIME
    public let type: String
    /// The subtype of the MIME
    public let subtype: String?
    /// An optional parameter, made of a key and a value
    public let parameter: HTTPMIMETypeParameter?

    /// Initializes a HTTP MIME type
    ///
    /// - Parameters:
    ///   - type: The type of the MIME
    ///   - subtype: The subtype of the MIME
    ///   - parameter: The parameter of the MIME
    public init(type: String, subtype: String? = nil, parameter: HTTPMIMETypeParameter? = nil) {
        self.type = type
        self.subtype = subtype
        self.parameter = parameter
    }

    /// :nodoc:
    public var description: String {
        var resultString: String = type.lowercased()
        if let subtype = subtype {
            resultString += "/\(subtype.lowercased())"
        }
        if let parameter = parameter {
            resultString += "; \(parameter.key)=\(parameter.value)"
        }
        return resultString
    }

    /// Octet stream MIME
    public static var octetStream: HTTPMIMEType {
        return HTTPMIMEType(type: "application", subtype: "octet-stream", parameter: nil)
    }

    /// Text plain MIME
    ///
    /// - Parameter charset: The charset of the text
    /// - Returns: A Text plain MIME
    public static func textPlain(charset: String? = nil) -> HTTPMIMEType {
        let parameter: HTTPMIMETypeParameter?
        if let charset = charset {
            parameter = HTTPMIMETypeParameter(key: "charset", value: charset)
        } else {
            parameter = nil
        }
        return HTTPMIMEType(type: "text", subtype: "plain", parameter: parameter)
    }
}

/// MIME Parameter
public struct HTTPMIMETypeParameter {
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
        self.key = key
        self.value = value
    }
}
