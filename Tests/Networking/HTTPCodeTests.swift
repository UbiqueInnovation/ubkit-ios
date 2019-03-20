//
//  HTTPCodeTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import UBFoundation
import XCTest

class HTTPCodeTests: XCTestCase {
    func testStandardHTTPCode() {
        let testData: [(status: Int, standard: StandardHTTPCode?)] = [
            (200, .OK),
            (404, .notFound),
            (2000, nil)
        ]

        for data in testData {
            let standard = data.status.standardHTTPCode
            XCTAssertEqual(standard, data.standard)
        }
    }

    func testHTTPCodeCategory() {
        let testData: [(statusCode: Int, category: HTTPCodeCategory)] = [
            (010, .uncategorized),
            (600, .uncategorized),
            (1600, .uncategorized),
            (201, .success),
            (210, .success),
            (299, .success),
            (300, .redirection),
            (404, .clientError),
            (501, .serverError),
            (150, .informational)
        ]

        for data in testData {
            let category = data.statusCode.httpCodeCategory
            XCTAssertEqual(category, data.category)
        }
    }
}
