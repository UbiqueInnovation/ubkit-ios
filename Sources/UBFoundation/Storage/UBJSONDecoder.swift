//
//  UBJSONDecoder.swift
//
//
//  Created by Stefan Mitterrutzner on 09.12.21.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

public class UBJSONDecoder: JSONDecoder {
    override public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        if #available(iOS 13.1, *) {
            return try super.decode(type, from: data)
        } else {
            // workaround if object is top level to support pre 13.1
            if T.self == Date?.self ||
                T.self == Bool?.self ||
                T.self == Date.self ||
                T.self == Bool.self ||
                T.self == String.self ||
                T.self == String?.self,
                let encodedString = String(data: data, encoding: .utf8) {
                let wrappedElement = "[\(encodedString)]"
                if let data = wrappedElement.data(using: .utf8),
                   let collection = try? super.decode([T].self, from: data),
                   let first = collection.first {
                    return first
                } else {
                    return try super.decode(type, from: data)
                }
            } else {
                return try super.decode(type, from: data)
            }
        }
    }
}
#endif
