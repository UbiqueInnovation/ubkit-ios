//
//  UBOptionalUserDefault.swift
//  UBFoundation
//
//  Created by Zeno Koller on 02.02.20.
//

import Foundation

/// Backs a variable of type `T?` with storage in UserDefaults, where `T` conforms to
/// `UBUserDefaultValue`.
/// For variables with default values, please use `UBUserDefault` instead.
///
/// Usage:
///       @UBOptionalUserDefault(key: "username_key")
///       var userName: String?
///
@propertyWrapper
public struct UBOptionalUserDefault<T: UBUserDefaultValue> {
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
    public var wrappedValue: T? {
        get {
            return T.retrieveOptional(from: userDefaults, key: key)
        }
        set {
            newValue?.store(in: userDefaults, key: key)
        }
    }
}
