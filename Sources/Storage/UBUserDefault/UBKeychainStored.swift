//
//  UBKeychainStored.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 31.03.20.
//

import Foundation

/// Backs a string variable with storage in Keychain.
/// The value is optional, thus if no value has previously been stored, nil
/// will be returned. The accessibility of the value is determined by the
/// accessibility property.
///
/// Usage:
///       @UBKeychainStored(key: "password_key", accessibility: .whenUnlockedThisDeviceOnly)
///       var deviceUUID: String?
///
@propertyWrapper
public struct UBKeychainStored {

    /// The key for the value
    public let key: String

    /// Defines the circumstances under which a value can be accessed.
    public let accessibility: UBKeychainAccessibility

    public init(key: String, accessibility: UBKeychainAccessibility) {
        self.key = key
        self.accessibility = accessibility
    }

    /// :nodoc:
    public var wrappedValue: String? {
        get {
            return UBKeychain.get(key)
        }
        set {
            guard let newValue = newValue else { return }
            UBKeychain.set(newValue, key: key, accessibility: accessibility)
        }
    }
}
