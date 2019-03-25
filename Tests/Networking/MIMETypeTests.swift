//
//  MIMETypeTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import UBFoundation
import XCTest

class MIMETypeTests: XCTestCase {
    func testCharacterEncoding() {
        XCTAssertEqual(MIMEType.Parameter(charsetForEncoding: .utf8)?.value, "utf-8")
        XCTAssertEqual(MIMEType.Parameter(charsetForEncoding: .ascii)?.value, "us-ascii")
    }

    func testEquatable() {
        XCTAssertTrue(MIMEType(type: .text, subtype: "plain").isEqual(.text(), ignoreParameter: false))
        XCTAssertTrue(MIMEType(type: .text, subtype: "plain").isEqual(.text(), ignoreParameter: true))
        XCTAssertTrue(MIMEType(type: .text, subtype: "plain", parameter: MIMEType.Parameter(charsetForEncoding: .utf8)).isEqual(.text(encoding: .utf8), ignoreParameter: false))
        XCTAssertTrue(MIMEType(type: .text, subtype: "plain", parameter: MIMEType.Parameter(charsetForEncoding: .utf8)).isEqual(.text(encoding: nil), ignoreParameter: true))
        XCTAssertFalse(MIMEType(type: .text, subtype: "plain").isEqual(.png, ignoreParameter: false))
        XCTAssertFalse(MIMEType(type: .text, subtype: "plain").isEqual(.png, ignoreParameter: true))
        XCTAssertFalse(MIMEType(type: .text, subtype: "plain", parameter: MIMEType.Parameter(charsetForEncoding: .utf8)).isEqual(.text(encoding: nil), ignoreParameter: false))
    }

    func testInitializingFromString() {
        let successTestData: [String] = [
            "image/png",
            "text/plain",
            "application/7zip",
            "application/json; charset=utf-8",
            "application/json; charset=UTF-8",
            "application/vnd.omads-email+xml",
            "application/clue_info+xml",
            "audio/vnd.nuera.ecelp4800"
        ]
        // Test the successful standard format
        for test in successTestData {
            let mime = MIMEType(string: test)
            XCTAssertNotNil(mime)
            XCTAssertEqual(mime?.stringValue, test)
        }

        let failureTestData: [String] = [
            "image", // Only type
            "image/", // Only type
            "mix[tape", // Only type
            "unknown/plain", // Unknow type
            "application/.plain", // Invalid subtype
            "application/+plain", // Invalid subtype
            "image/; charset=utf-8", // Missing subtype
            "image/ ; charset=utf-8", // Missing subtype
            "", // Missing Type
            "/", // Missing Type
            ";", // Missing Type
            "application/clue@info+xml", // Not allowed character
            "application/json; charset", // Parameter malformatted
            "application/json; charset=", // Parameter malformatted
            "application/json; =utf-8" // Parameter malformatted
        ]
        for test in failureTestData {
            XCTAssertNil(MIMEType(string: test))
        }
    }

    func testDescription() {
        XCTAssertEqual(MIMEType(type: .image, subtype: "png", parameter: nil).stringValue, "image/png")
        XCTAssertEqual(MIMEType(type: .text, subtype: "plain", parameter: MIMEType.Parameter(charsetForEncoding: .utf8)).stringValue, "text/plain; charset=utf-8")
    }

    func testPresets() {
        XCTAssertEqual(MIMEType.text(encoding: .utf8).stringValue, "text/plain; charset=utf-8")
        XCTAssertEqual(MIMEType.text().stringValue, "text/plain")
        XCTAssertEqual(MIMEType.multipartFormData(boundary: "A").stringValue, "multipart/form-data; boundary=A")
        XCTAssertEqual(MIMEType.json().stringValue, "application/json; charset=utf-8")
    }
}
