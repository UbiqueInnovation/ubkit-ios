//
//  UBDeviceUUIDTests.swift
//  UBFoundation iOS Tests
//
//  Created by Nicolas Märki on 29.03.20.
//

@testable import UBFoundation
import XCTest

class UBDeviceUUIDTests: XCTestCase {
    func testDeviceUUID() throws {
        let id1 = UBDeviceUUID.getUUID(storage: .userDefaults)
        let id2 = UBDeviceUUID.getUUID(storage: .userDefaults)
        XCTAssertEqual(id1, id2)
    }
}
