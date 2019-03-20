//
//  HTTPRequestBodyProviderTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import XCTest

class HTTPRequestBodyProviderTests: XCTestCase {
    func testData() {
        let data = "test".data(using: .utf8)!
        let body = try! data.httpRequestBody()
        XCTAssertEqual(body.data, data)
        XCTAssertEqual(body.mimeType.description, "application/octet-stream")
    }

    func testString() {
        let str = "test"
        let data = str.data(using: .utf8)!
        let body = try! str.httpRequestBody()
        XCTAssertEqual(String(data: data, encoding: .utf8), str)
        XCTAssertEqual(body.mimeType.description, "text/plain; charset=utf-8")
    }
}
