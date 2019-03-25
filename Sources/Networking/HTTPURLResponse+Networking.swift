//
//  HTTPURLResponse+Networking.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

extension HTTPURLResponse {
    /// Returns the header field for the key
    ///
    /// - Parameter key: A standard key
    /// - Returns: The value associated with the key
    public func getHeaderField(key: HTTPHeaderField.StandardKeys) -> String? {
        return allHeaderFields[key.rawValue] as? String
    }
}
