//
//  UserDefaultsDevTools.swift
//  DevTools
//
//  Created by Marco Zimmermann on 30.09.22.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

class UserDefaultsDevTools {
    static var sharedUserDefaults: UserDefaults?

    static func clearUserDefaults(_ defaults: UserDefaults) {
        defaults.dictionaryRepresentation().keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }

    static func setupSharedUserDefaults(_ userDefaults: UserDefaults) {
        sharedUserDefaults = userDefaults
    }
}
#endif
