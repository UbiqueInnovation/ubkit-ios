//
//  MockKeychain.swift
//  UBFoundation
//
//  Created by Stefan Mitterrutzner on 09.11.20.
//

@testable import UBFoundation
import XCTest

class MockKeychain: UBKeychainProtocol {
    var store: [String: Any] = [:]

    func set(_ value: String, key: String, accessibility _: UBKeychainAccessibility) -> Bool {
        store[key] = value.data(using: .utf8)
        return true
    }

    func set(_ value: Data, key: String, accessibility _: UBKeychainAccessibility) -> Bool {
        store[key] = value
        return true
    }

    func get(_ key: String) -> String? {
        guard let data = getData(key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    func getData(_ key: String) -> Data? {
        store[key] as? Data
    }

    func delete(_ key: String) -> Bool {
        store.removeValue(forKey: key) != nil
    }

    func deleteAllItems() -> Bool {
        store.removeAll()
        return true
    }
}
