//
//  HTTPRequestBodyTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import UBFoundation
import XCTest

class HTTPRequestBodyProviderTests: XCTestCase {
    func testData() {
        let data = "test".data(using: .utf8)!
        let body = try! data.httpRequestBody()
        XCTAssertEqual(body.data, data)
        XCTAssertEqual(body.mimeType.stringValue, "application/octet-stream")
    }

    func testString() {
        let str = "test"
        let data = str.data(using: .utf8)!
        let body = try! str.httpRequestBody()
        XCTAssertEqual(String(data: data, encoding: .utf8), str)
        XCTAssertEqual(body.mimeType.stringValue, "text/plain; charset=utf-8")
    }

    func testURLEncoding() {
        var encoder = UBHTTPRequestBodyURLEncoder(payload: ["A": "1", "b": "2", "C": "3"])
        let expectedResult = "A=1&C=3&b=2".data(using: .utf8)!
        do {
            let body = try encoder.httpRequestBody()
            XCTAssertEqual(body.data, expectedResult)
            XCTAssertEqual(body.mimeType.stringValue, "application/x-www-form-urlencoded")

            encoder.sendEncoding = true
            let body2 = try encoder.httpRequestBody()
            XCTAssertEqual(body2.data, expectedResult)
            XCTAssertEqual(body2.mimeType.stringValue, "application/x-www-form-urlencoded; charset=utf-8")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMultipartMultiple() {
        do {
            let parameter1 = UBURLRequestBodyMultipart.Parameter(name: "p1", value: "parameter1")
            let parameter2 = UBURLRequestBodyMultipart.Parameter(name: "p2", value: "parameter2")
            let payload1 = try UBURLRequestBodyMultipart.Payload(name: "d1", fileName: "f1", body: "d1f1")
            let payload2 = try UBURLRequestBodyMultipart.Payload(name: "d2", fileName: "f2", body: "d2f2")
            let multipart = UBURLRequestBodyMultipart(parameters: [parameter1, parameter2], payloads: [payload1, payload2], encoding: .utf8)
            let body = try multipart.httpRequestBody()

            XCTAssertEqual(body.mimeType.stringValue, "multipart/form-data; boundary=\(multipart.boundary)")

            let boundaryPrefix = "--\(multipart.boundary)\r\n"
            let endPrefix = "--\(multipart.boundary)--\r\n"

            let expectedString = "\(boundaryPrefix)Content-Disposition: form-data; name=\"p1\"\r\n\r\nparameter1\r\n\(boundaryPrefix)Content-Disposition: form-data; name=\"p2\"\r\n\r\nparameter2\r\n\(boundaryPrefix)Content-Disposition: form-data; name=\"d1\"; filename=\"f1\"\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nd1f1\r\n\(boundaryPrefix)Content-Disposition: form-data; name=\"d2\"; filename=\"f2\"\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nd2f2\r\n\(endPrefix)"
            let resultString = String(data: body.data, encoding: .utf8)
            XCTAssertEqual(resultString, expectedString)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMultipartPayloadOnly() {
        do {
            let payload1 = try UBURLRequestBodyMultipart.Payload(name: "d1", fileName: "f1", body: "d1f1")
            let multipart = UBURLRequestBodyMultipart(parameters: [], payloads: [payload1], encoding: .utf8)
            let body = try multipart.httpRequestBody()

            XCTAssertEqual(body.mimeType.stringValue, "multipart/form-data; boundary=\(multipart.boundary)")

            let boundaryPrefix = "--\(multipart.boundary)\r\n"
            let endPrefix = "--\(multipart.boundary)--\r\n"

            let expectedString = "\(boundaryPrefix)Content-Disposition: form-data; name=\"d1\"; filename=\"f1\"\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nd1f1\r\n\(endPrefix)"
            let resultString = String(data: body.data, encoding: .utf8)
            XCTAssertEqual(resultString, expectedString)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMultipartParameters() {
        do {
            let parameter1 = UBURLRequestBodyMultipart.Parameter(name: "p1", value: "parameter1")
            let parameter2 = UBURLRequestBodyMultipart.Parameter(name: "p2", value: "parameter2")
            let multipart = UBURLRequestBodyMultipart(parameters: [parameter1, parameter2], payloads: [], encoding: .utf8)
            let body = try multipart.httpRequestBody()

            XCTAssertEqual(body.mimeType.stringValue, "multipart/form-data; boundary=\(multipart.boundary)")

            let boundaryPrefix = "--\(multipart.boundary)\r\n"
            let endPrefix = "--\(multipart.boundary)--\r\n"

            let expectedString = "\(boundaryPrefix)Content-Disposition: form-data; name=\"p1\"\r\n\r\nparameter1\r\n\(boundaryPrefix)Content-Disposition: form-data; name=\"p2\"\r\n\r\nparameter2\r\n\(endPrefix)"
            let resultString = String(data: body.data, encoding: .utf8)
            XCTAssertEqual(resultString, expectedString)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMultipartNoParts() {
        let multipart = UBURLRequestBodyMultipart(parameters: [], payloads: [], encoding: .utf8)
        XCTAssertThrowsError(try multipart.httpRequestBody())
    }
}
#endif
