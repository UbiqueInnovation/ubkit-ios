//
//  Macros.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

import Foundation
import os

/// Uncomment the following line and copy this file to your project 

// typealias _PrintMacro = UBFoundation._PrintMacro

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@freestanding(expression)
public macro print(_ message: OSLogMessage) = #externalMacro(
    module: "UBMacros",
    type: "PrintMacro"
)

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@freestanding(expression)
public macro printError(_ message: String) = #externalMacro(
    module: "UBMacros",
    type: "PrintErrorMacro"
)

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@freestanding(expression)
public macro assert(_ condition: Bool, _ message: @autoclosure () -> String = String()) = #externalMacro(
    module: "UBMacros",
    type: "AssertMacro"
)

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@freestanding(expression)
public macro assertionFailure(_ message: @autoclosure () -> String = String()) = #externalMacro(
    module: "UBMacros",
    type: "AssertionFailureMacro"
)

@available(*, deprecated, message: "Use #print instead")
public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    Swift.print(items, separator: separator, terminator: terminator)
}

@available(*, deprecated, message: "Use #assert instead")
public func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    Swift.assert(condition(), message(), file: file, line: line)
}

@available(*, deprecated, message: "Use #assertionFailure instead")
public func assertionFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    Swift.assertionFailure(message(), file: file, line: line)
}


