//
//  HTTPDataDecoderTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 24.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import UBFoundation
import XCTest

class HTTPDataDecoderTests: XCTestCase {
    let response = HTTPURLResponse(url: URL(string: "http://ubique.ch")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!

    func testDataDecoderBlock() {
        let ex = expectation(description: "Block")
        let decoder = UBURLDataTaskDecoder { data, _ -> Data in
            ex.fulfill()
            return data
        }
        XCTAssertNoThrow(try decoder.decode(data: Data(), response: response))
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testStringDecoder() {
        let decoder = UBHTTPStringDecoder(encoding: .utf8)
        let test = "Hello"
        let testData = test.data(using: .utf8)!
        do {
            let result = try decoder.decode(data: testData, response: response)
            XCTAssertEqual(test, result)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testStringDecoderFail() {
        let decoder = UBHTTPStringDecoder(encoding: .utf8)
        let test = "Hello"
        let testData = test.data(using: .utf16)!
        XCTAssertThrowsError(try decoder.decode(data: testData, response: response))
    }

    func testJSONDecoder() {
        struct TestObject: Decodable {
            let value: String
        }
        let decoder = UBHTTPJSONDecoder<TestObject>()
        let testData = "{\"value\":\"A\"}".data(using: .utf8)!
        do {
            let result = try decoder.decode(data: testData, response: response)
            XCTAssertEqual(result.value, "A")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
#endif
