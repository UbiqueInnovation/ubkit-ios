//
//  UBUserDefaultTests.swift
//  UBFoundation
//
//  Created by Stefan Mitterrutzner on 09.11.20.
//

@testable import UBFoundation
import XCTest

class UBKeychainStoredTests: XCTestCase {
    func testDefaultValue() {
        let mockKeychain = MockKeychain()

        let value = UBKeychainStored<String>(key: "testKey", defaultValue: "defaultValue", accessibility: .whenUnlocked, keychain: mockKeychain)

        XCTAssertEqual(value.wrappedValue, "defaultValue")

        XCTAssertEqual(mockKeychain.get("testKey"), nil)
    }

    func testStoringOfString() {
        let mockKeychain = MockKeychain()

        var value = UBKeychainStored<String>(key: "testKey", defaultValue: "defaultValue", accessibility: .whenUnlocked, keychain: mockKeychain)

        value.wrappedValue = "newValue"

        XCTAssertEqual(value.wrappedValue, "newValue")

        XCTAssertEqual(mockKeychain.get("testKey"), "\"newValue\"")
    }

    func testStoringOptionalString() {
        let mockKeychain = MockKeychain()

        var value = UBKeychainStored<String?>(key: "testKey", defaultValue: "defaultValue", accessibility: .whenUnlocked, keychain: mockKeychain)

        XCTAssertEqual(value.wrappedValue, "defaultValue")

        value.wrappedValue = nil

        XCTAssertEqual(value.wrappedValue, nil)
    }

    func testMigratingOfOldStrings() {
        let mockKeychain = MockKeychain()

        _ = mockKeychain.set("oldValue", key: "testKey", accessibility: .whenUnlocked)

        var value = UBKeychainStored<String?>(key: "testKey", defaultValue: nil, accessibility: .whenUnlocked, keychain: mockKeychain)

        XCTAssertEqual(value.wrappedValue, "oldValue")

        value.wrappedValue = "newValue"

        XCTAssertEqual(value.wrappedValue, "newValue")

        value.wrappedValue = nil

        XCTAssertEqual(value.wrappedValue, nil)
    }

    func testCustomOptionalObject() {
        let mockKeychain = MockKeychain()

        let user = User(name: "name", birthdate: .init())

        var value = UBKeychainStored<User?>(key: "testKey", defaultValue: nil, accessibility: .whenUnlocked, keychain: mockKeychain)

        XCTAssertEqual(value.wrappedValue, nil)

        value.wrappedValue = user

        XCTAssertEqual(value.wrappedValue!, user)
    }

    func testCustomObject() {
        let mockKeychain = MockKeychain()

        let userDefault = User(name: "name", birthdate: .init())

        var value = UBKeychainStored<User?>(key: "testKey", defaultValue: userDefault, accessibility: .whenUnlocked, keychain: mockKeychain)

        XCTAssertEqual(value.wrappedValue, userDefault)

        let user = User(name: "newName", birthdate: .init())

        value.wrappedValue = user

        XCTAssertEqual(value.wrappedValue!, user)
    }

    // MARK: - Helper types

    struct User: Codable, Equatable {
        var name: String
        var birthdate: Date
    }
}
