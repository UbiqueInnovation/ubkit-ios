//
//  HTTPURLRequestTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import UBFoundation
import XCTest

class HTTPURLRequestTests: XCTestCase {
    let url = URL(string: "http://ubique.ch")!

    func testIntialization() {
        let timeout: TimeInterval = 34
        var request = UBURLRequest(url: url, timeoutInterval: timeout)
        XCTAssertEqual(url, request.url)
        XCTAssertEqual(timeout, request.timeoutInterval)

        request.httpMethod = UBHTTPMethod.get
        XCTAssertEqual(request.httpMethod?.rawValue, "GET")

        XCTAssertTrue(request.allowsCellularAccess)
        request.allowsCellularAccess = false
        XCTAssertFalse(request.allowsCellularAccess)

        request.networkServiceType = .background
        XCTAssertEqual(request.networkServiceType, URLRequest.NetworkServiceType.background)
    }

    func testBody() {
        var request = UBURLRequest(url: url)
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))

        let str = "Hello test"
        let body = try! str.httpRequestBody()
        XCTAssertNoThrow(try request.setHTTPBody(str))
        XCTAssertEqual(body.mimeType.stringValue, request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertEqual(request.httpBody, body.data)

        request.clearHTTPBody()
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
    }

    func testSetHTTPHeader() {
        var request = UBURLRequest(url: url)
        let key = "Hi"
        let value = "xcd"
        request.setHTTPHeaderField(UBHTTPHeaderField(key: key, value: value))
        XCTAssertEqual(request.value(forHTTPHeaderField: key), value)
        request.addToHTTPHeaderField(UBHTTPHeaderField(key: .contentType, value: "text/plain"))
        XCTAssertEqual(request.value(forHTTPHeaderField: key), value)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "text/plain")
        let all = request.allHTTPHeaderFields
        XCTAssertNotNil(all)
        XCTAssertEqual(all?[key], value)
    }

    func testQueryParameters() {
        let testData = ["a": "1", "b": "2"]
        var request = UBURLRequest(url: url)
        XCTAssertNoThrow(try request.setQueryParameters(testData))
        // The order of the parameters is arbitrary when it comes to dictionary
        XCTAssertTrue(request.url?.absoluteString == "http://ubique.ch?a=1&b=2" ? true : request.url?.absoluteString == "http://ubique.ch?b=2&a=1")
        XCTAssertNoThrow(try request.setQueryParameter(URLQueryItem(name: "a", value: "1")))
        XCTAssertEqual(request.url?.absoluteString, "http://ubique.ch?a=1")

        do {
            let all = try request.allQueryParameters()
            XCTAssertEqual(all.count, 1)
            let first = all.first
            XCTAssertNotNil(first)
            XCTAssertEqual(first?.name, "a")
            XCTAssertEqual(first?.value, "1")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testJSONBody() {
        struct T: Encodable {
            let a: String
        }
        var request = UBURLRequest(url: url)
        XCTAssertNoThrow(try request.setHTTPJSONBody(T(a: "Hello")))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=utf-8")
        XCTAssertNotNil(request.httpBody)
        if let data = request.httpBody {
            XCTAssertEqual(String(data: data, encoding: .utf8), "{\"a\":\"Hello\"}")
        }
    }
}
