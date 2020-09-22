//
//  UBRawRepresentable.swift
//  UBFoundation
//
//  Created by Zeno Koller on 02.02.20.
//

import Foundation

public protocol UBRawRepresentable: RawRepresentable, UBUserDefaultValue {}

extension UBRawRepresentable {
    public func store(in userDefaults: UserDefaults, key: String) {
        userDefaults.set(rawValue, forKey: key)
    }

    public static func retrieve(from userDefaults: UserDefaults, key: String, defaultValue: Self) -> Self {
        guard let value = userDefaults.object(forKey: key) as? Self.RawValue else {
            return defaultValue
        }
        return Self(rawValue: value) ?? defaultValue
    }

    public static func retrieveOptional(from _: UserDefaults, key: String) -> Self? {
        guard let value = UserDefaults.standard.object(forKey: key) as? Self.RawValue else {
            return nil
        }
        return Self(rawValue: value)
    }
}
