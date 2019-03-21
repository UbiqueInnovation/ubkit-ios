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
        let cache = URLRequest.CachePolicy.reloadIgnoringCacheData
        let timeout: TimeInterval = 34
        var request = HTTPURLRequest(url: url, cachePolicy: cache, timeoutInterval: timeout)
        XCTAssertEqual(url, request.url)
        XCTAssertEqual(cache, request.cachePolicy)
        XCTAssertEqual(timeout, request.timeoutInterval)

        request.httpMethod = HTTPMethod.get
        XCTAssertEqual(request.httpMethod?.rawValue, "GET")

        XCTAssertTrue(request.allowsCellularAccess)
        request.allowsCellularAccess = false
        XCTAssertFalse(request.allowsCellularAccess)

        request.networkServiceType = .background
        XCTAssertEqual(request.networkServiceType, URLRequest.NetworkServiceType.background)
    }

    func testBody() {
        var request = HTTPURLRequest(url: url)
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))

        let str = "Hello test"
        let body = try! str.httpRequestBody()
        XCTAssertNoThrow(try request.setHTTPBody(str))
        XCTAssertEqual(body.mimeType.description, request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertEqual(request.httpBody, body.data)

        request.clearHTTPBody()
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
    }

    func testSetHTTPHeader() {
        var request = HTTPURLRequest(url: url)
        let key = "Hi"
        let value = "xcd"
        request.setHTTPHeaderField(HTTPRequestHeaderField(key: key, value: value))
        XCTAssertEqual(request.value(forHTTPHeaderField: key), value)
        request.addToHTTPHeaderField(HTTPRequestHeaderField(contentType: "text"))
        XCTAssertEqual(request.value(forHTTPHeaderField: key), value)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "text")
        let all = request.allHTTPHeaderFields
        XCTAssertNotNil(all)
        XCTAssertEqual(all?[key], value)
    }

    func testQueryParameters() {
        let testData = ["a": "1", "b": "2"]
        var request = HTTPURLRequest(url: url)
        XCTAssertNoThrow(try request.setQueryParameters(testData))
        // The order of the parameters is arbitrary when it comes to dictionary
        XCTAssertTrue(request.url?.absoluteString == "http://ubique.ch?a=1&b=2" ? true : request.url?.absoluteString == "http://ubique.ch?b=2&a=1")
        XCTAssertNoThrow(try request.setQueryParameters(URLQueryItem(name: "a", value: "1")))
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
}
