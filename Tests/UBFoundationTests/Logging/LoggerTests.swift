//
//  LoggerTests.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

import UBFoundation
import XCTest

@available(iOS 14.0, *)
class LoggerTests: XCTestCase {
    func testMacro() {
        Log.debug("\(52.0)")

        let variable = "test"
        let variable2 = "test2"
        Log.debug(
            "Test = \(variable, privacy: .public), ? = \(variable2, privacy: .private)"
        )
    }

    func testError() async {
        let exp = expectation(description: "Failed")
        await UBNonFatalErrorReporter.shared.setHandler { _ in
            exp.fulfill()
        }

        Log.reportError("Failed to not fail")

        await fulfillment(of: [exp])
    }

    func testAssertTrue() {
        assert(true, "Test")
        assert(true)
    }

    func testAssertFalse() async {
        let exp = expectation(description: "Failed")
        await UBNonFatalErrorReporter.shared.setHandler { _ in
            exp.fulfill()
        }
        // swiftformat:disable all
        assert(false, "Test", swiftAssertionFailure: false)
        // swiftformat:enable all

        await fulfillment(of: [exp])
    }

    func testAssertionFailure() async {
        let exp = expectation(description: "Failed")
        exp.expectedFulfillmentCount = 2
        await UBNonFatalErrorReporter.shared.setHandler { _ in
            exp.fulfill()
        }

        assertionFailure("Failed", swiftAssertionFailure: false)
        assertionFailure(swiftAssertionFailure: false)

        await fulfillment(of: [exp])
    }
}
