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
        value(forHTTPHeaderField: headerKey)
    }

    /// Returns the header field for the key
    ///
    /// - Parameter key: List of keys
    /// - Returns: First matching value with one of the keys
    func ub_getHeaderField(key headerKeys: [String]) -> String? {
        headerKeys.compactMap { ub_getHeaderField(key: $0) }.first
    }
}
