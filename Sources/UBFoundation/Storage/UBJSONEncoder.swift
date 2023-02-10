//
//  UBJSONEncoder.swift
//
//
//  Created by Stefan Mitterrutzner on 09.12.21.
//

import Foundation

public class UBJSONEncoder: JSONEncoder {
    override public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        if #available(iOS 13.1, *) {
            return try super.encode(value)
        } else {
            // workaround if object is top level to support pre 13.1
            if T.self == Date?.self ||
                T.self == Bool?.self ||
                T.self == Date.self ||
                T.self == Bool.self ||
                T.self == String.self ||
                T.self == String?.self {
                let encodedDate = try super.encode([value])
                var encodedString = String(data: encodedDate, encoding: .utf8)
                // remove "[" and "]"
                encodedString?.removeLast()
                encodedString?.removeFirst()
                if let data = encodedString?.data(using: .utf8) {
                    return data
                } else {
                    return try super.encode(value)
                }
            } else {
                return try super.encode(value)
            }
        }
    }
}
