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
        XCTAssertEqual(response.ub_getHeaderField(key: .accept), "application/json")
        XCTAssertNil(response.ub_getHeaderField(key: .authorization))
    }
}
