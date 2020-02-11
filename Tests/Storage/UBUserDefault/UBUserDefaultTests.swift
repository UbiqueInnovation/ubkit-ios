//
//  UBUserDefaultTests.swift
//  UBFoundation
//
//  Created by Zeno Koller on 02.02.20.
//

@testable import UBFoundation
import XCTest

class UBUserDefaultTests: XCTestCase {
    @UBUserDefault(key: "testString", defaultValue: "Ubique")
    var testString: String

    @UBUserDefault(key: "testUser", defaultValue: User(name: "HANS MEIER", birthdate: Date.testDate))
    var testUser: User

    @UBUserDefault(key: "testColor", defaultValue: .blue)
    var testColor: Color

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

    func testDefaultValueCodable() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testUser.userDefaults = userDefaults

        XCTAssertEqual(testUser, User(name: "HANS MEIER", birthdate: Date.testDate))
    }

    func testGetCodable() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testUser.userDefaults = userDefaults

        let newUser = User(name: "Hans Meier", birthdate: Date())

        let data = try? JSONEncoder().encode(newUser)
        userDefaults.set(data, forKey: "testUser")

        XCTAssertEqual(testUser, newUser)
    }

    func testSetCodable() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testUser.userDefaults = userDefaults

        let insertedUser = User(name: "Hans Meier", birthdate: Date())

        testUser = insertedUser

        guard let data = userDefaults.object(forKey: "testUser") as? Data else {
            XCTFail()
            return
        }
        let retrievedUser = try? JSONDecoder().decode(User.self, from: data)

        XCTAssertEqual(retrievedUser, insertedUser)
    }

    func testDefaultValueRawRepresentable() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testColor.userDefaults = userDefaults

        XCTAssertEqual(testColor, .blue)
    }

    func testGetRawRepresentable() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testColor.userDefaults = userDefaults

        userDefaults.set(Color.green.rawValue, forKey: "testColor")

        XCTAssertEqual(testColor, .green)
    }

    func testSetRawRepresentable() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testColor.userDefaults = userDefaults

        testColor = .green

        guard let value = userDefaults.object(forKey: "testColor") as? Color.RawValue else {
            XCTFail()
            return
        }

        XCTAssertEqual(Color(rawValue: value), .green)
    }

    // MARK: - Helper types

    struct User: UBCodable, Equatable {
        var name: String
        var birthdate: Date
    }

    enum Color: String, UBRawRepresentable {
        case blue
        case green
    }
}

fileprivate extension Date {

    static var testDate: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: "2020-02-03")!
    }
}
