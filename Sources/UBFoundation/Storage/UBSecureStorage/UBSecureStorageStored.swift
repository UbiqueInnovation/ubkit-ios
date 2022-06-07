//
//  UBSecureStorageStored.swift
//
//
//  Created by Stefan Mitterrutzner on 07.06.22.
//

import Foundation

@available(iOS 11.0, *)
@propertyWrapper
public struct UBSecureStorageStored<Value: Codable> {
    /// The key for the value
    public let key: UBSecureStorageKey<Value>

    /// Optional default value if the key is not present in the Keychain
    public let defaultValue: Value

    /// keychain instance to use
    public let secureStorage: UBSecureStorage

    public init(key: String, defaultValue: Value, secureStorage: UBSecureStorage = UBSecureStorage.shared(accessibility: .whenUnlockedThisDeviceOnly)) {
        self.key = UBSecureStorageKey(key)
        self.defaultValue = defaultValue
        self.secureStorage = secureStorage
    }

    public var wrappedValue: Value {
        get {
            switch secureStorage.get(for: self.key) {
                case let .success(value):
                    return value
                case .failure:
                    return defaultValue
            }
        }
        set {
            secureStorage.set(newValue, for: key)
        }
    }
}
