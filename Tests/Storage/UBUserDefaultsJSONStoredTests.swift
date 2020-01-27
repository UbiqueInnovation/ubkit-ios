//
//  UBUserDefaultsJSONStoredTests.swift
//  UBFoundation
//
//  Created by Zeno Koller on 16.01.20.
//

@testable import UBFoundation
import XCTest

class UBUserDefaultsJSONStoredTests: XCTestCase {
    @UBUserDefaultsJSONStored(key: "testUser", defaultValue: User(name: "Hans Meier", birthdate: Date()))
    var testUser: User

    func testCodable() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testUser.userDefaults = userDefaults

        testUser.name = "Hansi"

        guard
            let data = userDefaults.object(forKey: "testUser") as? Data,
            let storedUser = try? JSONDecoder().decode(User.self, from: data)
        else {
            XCTFail()
            return
        }

        XCTAssertEqual(storedUser.name, "Hansi")
    }

    struct User: Codable {
        var name: String
        var birthdate: Date
    }
}
