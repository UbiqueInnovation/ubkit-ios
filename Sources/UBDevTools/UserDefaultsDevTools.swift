//
//  UserDefaultsDevTools.swift
//  DevTools
//
//  Created by Marco Zimmermann on 30.09.22.
//

import Foundation

class UserDefaultsDevTools {
    static func clearUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.dictionaryRepresentation().keys.forEach { (key) in
            defaults.removeObject(forKey: key)
        }
    }
}
