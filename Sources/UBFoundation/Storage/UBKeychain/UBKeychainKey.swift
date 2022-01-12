//
//  UBKeychainKey.swift
//
//
//  Created by Stefan Mitterrutzner on 08.12.21.
//

import Foundation

/// This is struct is needed to defer the type of a key when getting a object
public struct UBKeychainKey<Object: Codable> {
    let key: String
    public init(_ key: String) {
        self.key = key
    }
}
