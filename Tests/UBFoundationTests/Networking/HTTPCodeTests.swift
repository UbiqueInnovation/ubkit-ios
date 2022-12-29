//
//  HTTPCodeTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import UBFoundation
import XCTest

class HTTPCodeTests: XCTestCase {
    func testStandardHTTPCode() {
        let testData: [(status: Int, standard: UBStandardHTTPCode?)] = [
            (200, .ok),
            (404, .notFound),
            (2000, nil),
        ]

        for data in testData {
            let standard = data.status.ub_standardHTTPCode
            XCTAssertEqual(standard, data.standard)
        }
    }

    func testHTTPCodeCategory() {
        let testData: [(statusCode: Int, category: UBHTTPCodeCategory)] = [
            (010, .uncategorized),
            (600, .uncategorized),
            (1600, .uncategorized),
            (201, .success),
            (210, .success),
            (299, .success),
            (300, .redirection),
            (404, .clientError),
            (501, .serverError),
            (150, .informational),
        ]

        for data in testData {
            let category = data.statusCode.ub_httpCodeCategory
            XCTAssertEqual(category, data.category)
        }
    }
}
#endif
