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

    func testError() {
        let exp = expectation(description: "Failed")
        UBNonFatalErrorReporter.handler = { _ in
            exp.fulfill()
        }

        #printError("Failed to not fail")

        wait(for: [exp])
    }

    func testAssertTrue() {
        #assert(true, "Test")
        #assert(true)
    }

    func testAssertFalse() {
        let exp = expectation(description: "Failed")
        UBNonFatalErrorReporter.handler = { _ in 
            exp.fulfill()
        }

        #assert(false, "Test")

        wait(for: [exp])
    }

    func testAssertionFailure() {
        let exp = expectation(description: "Failed")
        exp.expectedFulfillmentCount = 2
        UBNonFatalErrorReporter.handler = { _ in
            exp.fulfill()
        }

        #assertionFailure("Failed")
        #assertionFailure()

        wait(for: [exp])
    }
}


