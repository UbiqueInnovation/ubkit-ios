//
//  MacroTests.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

import UBFoundation
import XCTest

@available(iOS 14.0, *)
class MacroTests: XCTestCase {
    func testMacro() {
        #print("\(52.0)")

        let variable = "test"
        #print("Test = \(variable, privacy: .public)")
    }

    func testError() async {
        let exp = expectation(description: "Failed")
        await UBNonFatalErrorReporter.shared.setHandler { _ in
            exp.fulfill()
        }

        #printError("Failed to not fail")

        await fulfillment(of: [exp])
    }

    func testAssertTrue() {
        #assert(true, "Test")
        #assert(true)
    }

    func testAssertFalse() async {
        let exp = expectation(description: "Failed")
        await UBNonFatalErrorReporter.shared.setHandler { _ in
            exp.fulfill()
        }
        _PrintMacro.disableAssertionFailure = true
        #assert(false, "Test")

        await fulfillment(of: [exp])
    }

    func testAssertionFailure() async {
        let exp = expectation(description: "Failed")
        exp.expectedFulfillmentCount = 2
        await UBNonFatalErrorReporter.shared.setHandler { _ in
            exp.fulfill()
        }

        _PrintMacro.disableAssertionFailure = true

        #assertionFailure("Failed")
        #assertionFailure()

        await fulfillment(of: [exp])
    }
}
