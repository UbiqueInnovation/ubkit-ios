//
//  MIMEType.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// A MIME type
/// - seeAlso: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
public struct MIMEType {
    /// The type of the MIME
    public var type: StandardType
    /// The subtype of the MIME
    public var subtype: String
    /// An optional parameter, made of a key and a value
    public var parameter: Parameter?

    /// Initializes a MIME type
    ///
    /// - Parameters:
    ///   - type: The type of the MIME
    ///   - subtype: The subtype of the MIME
    ///   - parameter: The parameter of the MIME
    public init(type: StandardType, subtype: String, parameter: Parameter? = nil) {
        self.type = type
        self.subtype = subtype.trimmingCharacters(in: .whitespaces).lowercased()
        self.parameter = parameter
    }

    /// Initializes a MIME Type from a string
    ///
    /// - Parameter string: The string to parse
    public init?(string: String) {
        let desc = string.trimmingCharacters(in: .whitespaces)
        let typeRegex = try! NSRegularExpression(pattern: "^([a-z]+)\\/([a-z0-9][a-z0-9\\p{Pd}.\\+_]*)(;\\s*([a-z0-9\\p{Pd}._]+)=([a-z0-9\\p{Pd}._]+))?$", options: .caseInsensitive)

        guard let typeResult = typeRegex.firstMatch(in: desc, range: NSRange(desc.startIndex..., in: desc)) else {
            return nil
        }

        guard typeResult.numberOfRanges >= 3,
            let typeCapturedRange = Range(typeResult.range(at: 1), in: desc),
            let subtypeCapturedRange = Range(typeResult.range(at: 2), in: desc) else {
            return nil
        }

        guard let type = MIMEType.StandardType(rawValue: String(desc[typeCapturedRange])) else {
            return nil
        }
        let subtype = String(desc[subtypeCapturedRange])

        let parameter: Parameter?
        if typeResult.numberOfRanges == 6, let keyCapturedRange = Range(typeResult.range(at: 4), in: desc),
            let valueCapturedRange = Range(typeResult.range(at: 5), in: desc) {
            let key = String(desc[keyCapturedRange])
            let value = String(desc[valueCapturedRange])
            parameter = Parameter(key: key, value: value)
        } else {
            parameter = nil
        }

        self.init(type: type, subtype: subtype, parameter: parameter)
    }

    /// The MIME type formatted as a String
    public var stringValue: String {
        var resultString: String = type.rawValue + "/" + subtype
        if let parameter = parameter {
            resultString += "; " + parameter.key + "=" + parameter.value
        }
        return resultString
    }

    /// Check if equal to another MIMEType
    ///
    /// - Parameters:
    ///   - to: The MIME type to check equality
    ///   - ignoreParameter: If we ignore the paramter in the comparison
    /// - Returns: `true` if they are equal
    public func isEqual(_ to: MIMEType, ignoreParameter: Bool) -> Bool {
        let comparison = (type == to.type) && (subtype == to.subtype)
        if ignoreParameter {
            return comparison
        }
        return comparison && (parameter == to.parameter)
    }
}
