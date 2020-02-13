//
//  UBOptionalUserDefaultTests.swift
//  UBFoundation
//
//  Created by Zeno Koller on 02.02.20.
//

@testable import UBFoundation
import XCTest

class UBOptionalUserDefaultTests: XCTestCase {
    @UBOptionalUserDefault(key: "testString")
    var testString: String?

    func testNoDefaultValue() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testString.userDefaults = userDefaults

        XCTAssertEqual(testString, nil)
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
}
