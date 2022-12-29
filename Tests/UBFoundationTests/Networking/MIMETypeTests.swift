//
//  MIMETypeTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import UBFoundation
import XCTest

class MIMETypeTests: XCTestCase {
    func testCharacterEncoding() {
        XCTAssertEqual(UBMIMEType.Parameter(charsetForEncoding: .utf8)?.value, "utf-8")
        XCTAssertEqual(UBMIMEType.Parameter(charsetForEncoding: .ascii)?.value, "us-ascii")
    }

    func testEquatable() {
        XCTAssertTrue(UBMIMEType(type: .text, subtype: "plain").isEqual(.text(), ignoreParameter: false))
        XCTAssertTrue(UBMIMEType(type: .text, subtype: "plain").isEqual(.text(), ignoreParameter: true))
        XCTAssertTrue(UBMIMEType(type: .text, subtype: "plain", parameter: UBMIMEType.Parameter(charsetForEncoding: .utf8)).isEqual(.text(encoding: .utf8), ignoreParameter: false))
        XCTAssertTrue(UBMIMEType(type: .text, subtype: "plain", parameter: UBMIMEType.Parameter(charsetForEncoding: .utf8)).isEqual(.text(encoding: nil), ignoreParameter: true))
        XCTAssertFalse(UBMIMEType(type: .text, subtype: "plain").isEqual(.png, ignoreParameter: false))
        XCTAssertFalse(UBMIMEType(type: .text, subtype: "plain").isEqual(.png, ignoreParameter: true))
        XCTAssertFalse(UBMIMEType(type: .text, subtype: "plain", parameter: UBMIMEType.Parameter(charsetForEncoding: .utf8)).isEqual(.text(encoding: nil), ignoreParameter: false))
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
            "audio/vnd.nuera.ecelp4800",
        ]
        // Test the successful standard format
        for test in successTestData {
            let mime = UBMIMEType(string: test)
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
            "application/json; =utf-8", // Parameter malformatted
        ]
        for test in failureTestData {
            XCTAssertNil(UBMIMEType(string: test))
        }
    }

    func testDescription() {
        XCTAssertEqual(UBMIMEType(type: .image, subtype: "png", parameter: nil).stringValue, "image/png")
        XCTAssertEqual(UBMIMEType(type: .text, subtype: "plain", parameter: UBMIMEType.Parameter(charsetForEncoding: .utf8)).stringValue, "text/plain; charset=utf-8")
    }

    func testPresets() {
        XCTAssertEqual(UBMIMEType.text(encoding: .utf8).stringValue, "text/plain; charset=utf-8")
        XCTAssertEqual(UBMIMEType.text().stringValue, "text/plain")
        XCTAssertEqual(UBMIMEType.multipartFormData(boundary: "A").stringValue, "multipart/form-data; boundary=A")
        XCTAssertEqual(UBMIMEType.json().stringValue, "application/json; charset=utf-8")
    }
}
#endif
