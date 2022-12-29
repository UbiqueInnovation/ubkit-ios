//
//  UBUserDefaultTests.swift
//  UBFoundation
//
//  Created by Zeno Koller on 02.02.20.
//
#if os(iOS) || os(tvOS) || os(watchOS)

@testable import UBFoundation
import XCTest

class UBUserDefaultTests: XCTestCase {
    @UBUserDefault(key: "testString", defaultValue: "Ubique")
    var testString: String

    @UBUserDefault(key: "testUser", defaultValue: .hansMeier)
    var testUser: User

    @UBUserDefault(key: "testOptionalString", defaultValue: nil)
    var testOptionalString: String?

    @UBUserDefault(key: "testOptionalUser", defaultValue: nil)
    var testOptionalUser: User?

    @UBUserDefault(key: "testColor", defaultValue: .blue)
    var testColor: Color

    @UBUserDefault(key: "testUsers", defaultValue: [])
    var testUsers: [User]

    @UBUserDefault(key: "testUserDictionary", defaultValue: [:])
    var testUserDictionary: [String: User]

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

        testUser = User.hansMeierReloaded

        guard let data = userDefaults.object(forKey: "testUser") as? Data else {
            XCTFail()
            return
        }
        let retrievedUser = try? JSONDecoder().decode(User.self, from: data)
        XCTAssertEqual(retrievedUser, User.hansMeierReloaded)
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

    func testNilDefaultValue() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testOptionalUser.userDefaults = userDefaults

        XCTAssertEqual(testOptionalUser, nil)
    }

    func testGetOptional() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testOptionalUser.userDefaults = userDefaults

        let data = try? JSONEncoder().encode(User.hansMeierReloaded)
        userDefaults.set(data, forKey: "testOptionalUser")
        XCTAssertEqual(testOptionalUser, User.hansMeierReloaded)
    }

    func testSetOptionalToValue() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testOptionalUser.userDefaults = userDefaults

        testOptionalUser = User.hansMeierReloaded

        guard let data = userDefaults.object(forKey: "testOptionalUser") as? Data else {
            XCTFail()
            return
        }
        let retrievedUser = try? JSONDecoder().decode(User.self, from: data)
        XCTAssertEqual(retrievedUser, User.hansMeierReloaded)
    }

    func testSetOptionalToNil() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testOptionalString.userDefaults = userDefaults

        testOptionalString = "Non-nil value"
        XCTAssertEqual(userDefaults.string(forKey: "testOptionalString"), "Non-nil value")

        testOptionalString = nil
        XCTAssertEqual(userDefaults.string(forKey: "testOptionalString"), nil)
    }

    func testSetCodableArray() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testUsers.userDefaults = userDefaults

        let insertedUsers = [
            User(name: "VRENI MÜLLER", birthdate: Date.testDate),
            User(name: "HANS MEIER", birthdate: Date.testDate),
        ]

        testUsers = insertedUsers

        guard let datas = userDefaults.object(forKey: "testUsers") as? [Data] else { XCTFail()
            return
        }

        let retrievedUsers = datas.compactMap { try? JSONDecoder().decode(User.self, from: $0) }
        XCTAssertEqual(retrievedUsers, insertedUsers)
    }

    func testGetCodableDictionary() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testUserDictionary.userDefaults = userDefaults

        let insertedUsers = [
            "first": User(name: "VRENI MÜLLER", birthdate: Date.testDate),
            "second": User(name: "HANS MEIER", birthdate: Date.testDate),
        ]

        let data = insertedUsers.compactMapValues { try? JSONEncoder().encode($0) }

        userDefaults.set(data, forKey: "testUserDictionary")

        testUserDictionary = insertedUsers

        XCTAssertEqual(testUserDictionary, insertedUsers)
    }

    func testSetCodableDictionary() {
        let userDefaults = UserDefaults.makeTestInstance()
        _testUserDictionary.userDefaults = userDefaults

        let insertedUsers = [
            "first": User(name: "VRENI MÜLLER", birthdate: Date.testDate),
            "second": User(name: "HANS MEIER", birthdate: Date.testDate),
        ]

        testUserDictionary = insertedUsers

        guard let datas = userDefaults.object(forKey: "testUserDictionary") as? [String: Data] else { XCTFail()
            return
        }

        let retrievedUsers = datas.compactMapValues { try? JSONDecoder().decode(User.self, from: $0) }
        XCTAssertEqual(retrievedUsers, insertedUsers)
    }

    // MARK: - Helper types

    struct User: UBCodable, Equatable {
        var name: String
        var birthdate: Date

        static var hansMeier = User(name: "HANS MEIER", birthdate: Date.testDate)
        static var hansMeierReloaded = User(name: "HANS MEIER", birthdate: Date())
    }

    enum Color: String, UBRawRepresentable {
        case blue
        case green
    }
}

private extension Date {
    static var testDate: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: "2020-02-03")!
    }
}
#endif
