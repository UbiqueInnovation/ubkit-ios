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
        var obe = "Hello"
        #printError("Failed to not fail \(obe)")
    }
}
