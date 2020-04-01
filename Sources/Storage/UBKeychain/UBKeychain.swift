//
//  UBKeychainStored.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 31.03.20.
//

import Foundation

class UBKeychain {

    /// :nodoc:
    @discardableResult
    static func set(_ value: String, key: String, accessibility: UBKeychainAccessibility) -> Bool {
        guard let data = value.data(using: .utf8, allowLossyConversion: false) else {
            return false
        }
        return UBKeychain.set(data, key: key, accessibility: accessibility)
    }

    /// :nodoc:
    @discardableResult
    static func set(_ value: Data, key: String, accessibility: UBKeychainAccessibility) -> Bool {
        let query = [
            kSecAttrAccount as String : key,
            kSecValueData as String   : value,
            kSecAttrAccessible as String : accessibility.rawValue,
            // We use genericPassword instead of internet password because
            // the value is not assiciated with a server
            kSecClass as String       : kSecClassGenericPassword] as [String : Any]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// :nodoc:
    static func get(_ key: String) -> String? {
        guard let data = getData(key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    /// :nodoc:
    static func getData(_ key: String) -> Data? {
        let query = [
            kSecAttrAccount as String : key,
            kSecClass as String       : kSecClassGenericPassword,
            kSecReturnData as String  : true,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var result: AnyObject? = nil
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        } else {
            return nil
        }
    }
}

