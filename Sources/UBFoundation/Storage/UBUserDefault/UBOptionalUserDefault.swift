//
//  UBOptionalUserDefault.swift
//  UBFoundation
//
//  Created by Zeno Koller on 02.02.20.
//

import Foundation


/// Deprecated, please use @UBUserDefault(key: "something", defaultValue: nil) instead.
///
/// Usage:
///       @UBOptionalUserDefault(key: "username_key")
///       var userName: String?
///
@propertyWrapper
@available(*, deprecated, message: "lease use @UBUserDefault(key: \"something\", defaultValue: nil) instead")
public struct UBOptionalUserDefault<Value: UBUserDefaultValue> {
    /// The key of the UserDefaults entry
    public let key: String
    /// The UserDefaults used for storage
    var userDefaults: UserDefaults

    /// :nodoc:
    public init(key: String, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = userDefaults
    }

    /// :nodoc:
    public var wrappedValue: Value? {
        get {
            userDefaults.object(forKey: key).flatMap(Value.init(with:))
        }
        set {
            newValue.object().map { userDefaults.set($0, forKey: key) }
                ?? userDefaults.removeObject(forKey: key)
        }
    }
}
