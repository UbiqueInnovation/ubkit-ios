//
//  HTTPMIMETypeTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import UBFoundation
import XCTest

class HTTPMIMETypeTests: XCTestCase {
    func testDescription() {
        XCTAssertEqual(HTTPMIMEType(type: "image", subtype: "png", parameter: nil).description, "image/png")
        XCTAssertEqual(HTTPMIMEType(type: "text", subtype: nil, parameter: nil).description, "text")
        XCTAssertEqual(HTTPMIMEType(type: "text", subtype: "plain", parameter: ("charset", "utf-8")).description, "text/plain; charset=utf-8")
    }

    func testTextPlain() {
        XCTAssertEqual(HTTPMIMEType.textPlain(charset: "utf-8").description, "text/plain; charset=utf-8")
        XCTAssertEqual(HTTPMIMEType.textPlain().description, "text/plain")
    }
}
