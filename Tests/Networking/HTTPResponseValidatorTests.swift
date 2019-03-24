//
//  HTTPResponseValidatorTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 24.03.19.
//

import UBFoundation
import XCTest

class HTTPResponseValidatorTests: XCTestCase {
    let url = URL(string: "http://ubique.ch")!

    func testBlockSuccess() {
        let ex = expectation(description: "validating")

        let validator = HTTPResponseValidatorBlock { response, data in
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertNotNil(data)
            ex.fulfill()
        }

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        XCTAssertNoThrow(try validator.validateHTTPResponse(response, data: "1".data(using: .utf8)!))

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testBlockFail() {
        let ex = expectation(description: "validating")

        let validator = HTTPResponseValidatorBlock { _, _ in
            ex.fulfill()
            throw NetworkingError.missingURL
        }

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        XCTAssertThrowsError(try validator.validateHTTPResponse(response, data: "1".data(using: .utf8)!))

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testNoBody() {
        let validator = HTTPResponseBodyNotEmptyValidator()
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        XCTAssertThrowsError(try validator.validateHTTPResponse(response, data: nil))
        XCTAssertThrowsError(try validator.validateHTTPResponse(response, data: Data()))
        XCTAssertNoThrow(try validator.validateHTTPResponse(response, data: "1".data(using: .utf8)!))
    }

    func testMIME() {
        let validator = HTTPResponseContentTypeValidator(expectedMIMEType: .json())
        let responseNO = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        let responseYES = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: ["content-type": "application/json"])!
        let responseYES2 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: ["Content-Type": "application/json"])!
        let responseYES3 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: ["CONTENT-TYPE": "application/json"])!
        let responseYES4 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: ["Content-type": "application/json"])!

        XCTAssertThrowsError(try validator.validateHTTPResponse(responseNO, data: nil))
        XCTAssertNoThrow(try validator.validateHTTPResponse(responseYES, data: nil))
        XCTAssertNoThrow(try validator.validateHTTPResponse(responseYES2, data: nil))
        XCTAssertNoThrow(try validator.validateHTTPResponse(responseYES3, data: nil))
        XCTAssertNoThrow(try validator.validateHTTPResponse(responseYES4, data: nil))
    }

    func testStatusCodeRange() {
        let validator = HTTPResponseStatusValidator(.success)

        let response200 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        let response201 = HTTPURLResponse(url: url, statusCode: 201, httpVersion: "1.1", headerFields: nil)!
        let response404 = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "1.1", headerFields: nil)!

        XCTAssertThrowsError(try validator.validateHTTPResponse(response404, data: nil), "") { error in
            XCTAssertEqual(error as? NetworkingError, NetworkingError.responseStatusValidationFailed(status: 404))
        }
        XCTAssertNoThrow(try validator.validateHTTPResponse(response200, data: nil))
        XCTAssertNoThrow(try validator.validateHTTPResponse(response201, data: nil))
    }

    func testStatusCodeSingleValue() {
        let validator = HTTPResponseStatusValidator(.serverError)

        let response200 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        let response500 = HTTPURLResponse(url: url, statusCode: 500, httpVersion: "1.1", headerFields: nil)!

        XCTAssertThrowsError(try validator.validateHTTPResponse(response200, data: nil), "") { error in
            XCTAssertEqual(error as? NetworkingError, NetworkingError.responseStatusValidationFailed(status: 200))
        }
        XCTAssertNoThrow(try validator.validateHTTPResponse(response500, data: nil))
    }

    func testStatusCodeMultipleValues() {
        let validator = HTTPResponseStatusValidator([.ok, .created])

        let response200 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        let response201 = HTTPURLResponse(url: url, statusCode: 201, httpVersion: "1.1", headerFields: nil)!
        let response404 = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "1.1", headerFields: nil)!

        XCTAssertThrowsError(try validator.validateHTTPResponse(response404, data: nil), "") { error in
            XCTAssertEqual(error as? NetworkingError, NetworkingError.responseStatusValidationFailed(status: 404))
        }
        XCTAssertNoThrow(try validator.validateHTTPResponse(response200, data: nil))
        XCTAssertNoThrow(try validator.validateHTTPResponse(response201, data: nil))
    }
}
