//
//  UBUserDefaultsJSONStored.swift
//  UBFoundation
//
//  Created by Zeno Koller on 16.01.20.
//

import Foundation

/// Backs a variable of type `T` with storage in UserDefaults, where `T` conforms to
/// `Codable`.
///
/// Usage:
///       @UBUserDefaultsJSONStored(key: "user", defaultValue: "" )
///       var user: User
///
/// Based on https://gist.github.com/LeeKahSeng/20e0c3602d1141af3bcff45f1f02df10
@propertyWrapper
public struct UBUserDefaultsJSONStored<T: Codable> {
    /// The key of the UserDefaults entry
    private let key: String
    /// The default value of the backing UserDefaults entry
    private let defaultValue: T
    /// The UserDefaults used for storage
    var userDefaults: UserDefaults

    /// :nodoc:
    public init(key: String, defaultValue: T, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    /// :nodoc:
    public var wrappedValue: T {
        get {
            guard let data = userDefaults.object(forKey: key) as? Data else {
                return defaultValue
            }
            let value = try? JSONDecoder().decode(T.self, from: data)
            return value ?? defaultValue
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            userDefaults.set(data, forKey: key)
        }
    }
}
