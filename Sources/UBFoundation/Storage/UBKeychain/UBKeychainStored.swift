//
//  UBKeychainStored.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 31.03.20.
//

import Foundation

/// Backs a variable with storage in Keychain.
/// The value can be optional, thus if no value has previously been stored, nil
/// will be returned. The accessibility property determines where the value can be accessed.
///
/// Usage:
/// @UBKeychainStored(key: "UBDeviceUUID", defaultValue: nil, accessibility: .whenUnlockedThisDeviceOnly)
/// private static var keychainDeviecUUID: String?
///
@propertyWrapper
public struct UBKeychainStored<Value: Codable> {

    /// The key for the value
    public let key: UBKeychainKey<Value>

    /// Defines the circumstances under which a value can be accessed.
    public let accessibility: UBKeychainAccessibility

    /// Optional default value if the key is not present in the Keychain
    public let defaultValue: Value

    /// keychain instance to use
    public let keychain: UBKeychainProtocol

    public init(key: String, defaultValue: Value, accessibility: UBKeychainAccessibility, keychain: UBKeychainProtocol = UBKeychain()) {
        self.key = UBKeychainKey(key)
        self.accessibility = accessibility
        self.defaultValue = defaultValue
        self.keychain = keychain
    }

    public var wrappedValue: Value {
        get {
            switch keychain.get(for: self.key) {
            case let .success(value):
                return value
            case .failure:
                // fallback for old installations since strings used to be stored utf8 endoced
                // on next write the value will be written JSON encoded
                switch keychain.getData(key.key) {
                case let .success(data):
                    if let string = String(data: data, encoding: .utf8), string is Value {
                        return string as! Value
                    }
                default:
                    break
                }
                return defaultValue
            }
        }
        set {
            keychain.set(newValue, for: key, accessibility: accessibility)
        }
    }
}
