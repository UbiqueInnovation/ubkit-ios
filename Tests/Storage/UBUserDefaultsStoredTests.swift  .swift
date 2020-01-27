//
//  UBUserDefaultsStoredTests.swift
//  UBFoundation
//
//  Created by Zeno Koller on 14.01.20.
//

@testable import UBFoundation
import XCTest

class UBUserDefaultsStoredTests: XCTestCase {
    @UBUserDefaultsStored(key: "testString", defaultValue: "Ubique")
    var testString: String

    func testDefaultValue() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testString.userDefaults = userDefaults

        XCTAssertEqual(testString, "Ubique")
    }

    func testGet() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testString.userDefaults = userDefaults

        userDefaults.set("Some value", forKey: "testString")
        XCTAssertEqual(testString, "Some value")
    }

    func testSet() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testString.userDefaults = userDefaults

        testString = "Some other value"
        XCTAssertEqual(userDefaults.string(forKey: "testString"), "Some other value")
    }

    struct User: Codable {
        var name: String
        var birthdate: Date
    }
}
