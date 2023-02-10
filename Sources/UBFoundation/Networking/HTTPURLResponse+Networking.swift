//
//  HTTPURLResponse+Networking.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

public extension HTTPURLResponse {
    /// Returns the header field for the key
    ///
    /// - Parameter key: A standard key
    /// - Returns: The value associated with the key
    func ub_getHeaderField(key: UBHTTPHeaderField.StandardKeys) -> String? {
        ub_getHeaderField(key: key.rawValue)
    }

    /// Returns the header field for the key
    ///
    /// - Parameter key: A standard key
    /// - Returns: The value associated with the key
    func ub_getHeaderField(key headerKey: String) -> String? {
        if #available(iOS 13.0, watchOS 6.0, macOS 10.15, *) {
            return value(forHTTPHeaderField: headerKey)
        } else {
            return allHeaderFields.getCaseInsensitiveValue(key: headerKey) as? String
        }
    }
}
