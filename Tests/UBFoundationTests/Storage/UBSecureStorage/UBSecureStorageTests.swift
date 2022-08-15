//
//  UBSecureStorageTests.swift
//  
//
//  Created by Stefan Mitterrutzner on 15.08.22.
//

@testable import UBFoundation
import XCTest

class UBSecureStorageTests: XCTestCase {
    func testSecureStorage(){
        let storage = UBSecureStorage(
            fileName: "test",
            keyProvider: MockKeyProvider()
        )

        storage.deleteAllItems()

        struct TestStruct: Codable {
            let name: String
        }

        let key = UBSecureStorageKey<TestStruct>("testKey")

        storage.set(TestStruct(name: "Name"), for: key)

        let object = storage.get(for: key)

        switch object {
            case let .success(st):
                XCTAssertEqual(st.name, "Name")
            case .failure:
                XCTFail()
        }
    }
}
