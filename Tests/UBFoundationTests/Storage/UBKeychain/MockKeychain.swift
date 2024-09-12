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

    var identifier: String = "MockKeychain"

    func get<T: Codable>(for key: UBKeychainKey<T>) -> Result<T, UBKeychainError> {
        if store.keys.contains(key.key),
           let i = store[key.key] as? T {
            return .success(i)
        }
        return .failure(.notFound)
    }

    func getData(_ key: String) -> Result<Data, UBKeychainError> {
        if let i = store[key] as? Data {
            return .success(i)
        }
        if let i = store[key] as? String {
            return .success(i.data(using: .utf8)!)
        }
        return .failure(.notFound)
    }

    @discardableResult
    func set<T>(_ object: T, for key: UBKeychainKey<T>, accessibility _: UBKeychainAccessibility) -> Result<Void, UBKeychainError> where T: Decodable, T: Encodable {
        store[key.key] = object
        return .success(())
    }

    func delete(for key: UBKeychainKey<some Any>) -> Result<Void, UBKeychainError> {
        store.removeValue(forKey: key.key)
        return .success(())
    }

    func deleteAllItems() -> Result<Void, UBKeychainError> {
        store.removeAll()
        return .success(())
    }

    func reset() {
        store.removeAll()
    }
}
