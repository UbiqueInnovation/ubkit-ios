//
//  HTTPURLResponseTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 24.03.19.
//

import UBFoundation
import XCTest

class HTTPURLResponseTests: XCTestCase {
    func testHeaderExtraction() {
        let response = HTTPURLResponse(url: URL(string: "http://ubique.ch")!, statusCode: 200, httpVersion: "1.1", headerFields: ["Accept": "application/json"])!
        XCTAssertEqual(response.getHeaderField(key: .accept), "application/json")
        XCTAssertNil(response.getHeaderField(key: .authorization))
    }
}
