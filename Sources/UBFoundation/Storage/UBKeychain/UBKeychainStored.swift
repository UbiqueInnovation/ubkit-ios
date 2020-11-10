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
    public let key: String

    /// Defines the circumstances under which a value can be accessed.
    public let accessibility: UBKeychainAccessibility

    /// Optional default value if the key is not present in the Keychain
    public let defaultValue: Value

    /// keychain instance to use
    public let keychain: UBKeychainProtocol

    init(key: String, defaultValue: Value, accessibility: UBKeychainAccessibility, keychain: UBKeychainProtocol = UBKeychain.shared) {
        self.key = key
        self.accessibility = accessibility
        self.defaultValue = defaultValue
        self.keychain = keychain
    }

    public var wrappedValue: Value {
        get {
            guard let data = keychain.getData(key) else { return defaultValue }
            let decoder = JSONDecoder()
            guard let decodedValue = try? decoder.decode(Value.self, from: data) else {
                // fallback for old installations since strings used to be stored utf8 endoced
                // on next write the value will be written JSON encoded
                if let string = String(data: data, encoding: .utf8), string is Value {
                    return string as! Value
                }
                return defaultValue
            }
            return decodedValue
        }
        set {
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(newValue) else { return }
            keychain.set(data, key: key, accessibility: accessibility)
        }
    }
}
