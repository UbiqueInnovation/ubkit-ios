//
//  Macros.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

import Foundation
import os

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@freestanding(expression)
public macro print(_ message: OSLogMessage) = #externalMacro(
    module: "UBMacros",
    type: "UBPrintMacro"
)

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@freestanding(expression)
public macro printError(_ message: String) = #externalMacro(
    module: "UBMacros",
    type: "UBPrintErrorMacro"
)

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@freestanding(expression)
public macro assert(_ condition: Bool, _ message: @autoclosure () -> String = String()) = #externalMacro(
    module: "UBMacros",
    type: "UBAssertMacro"
)

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@freestanding(expression)
public macro assertionFailure(_ message: @autoclosure () -> String = String()) = #externalMacro(
    module: "UBMacros",
    type: "UBAssertionFailureMacro"
)

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public struct UBPrintMacro {
    public static let Logger = os.Logger(subsystem: "UBLog", category: "Default")

    @_transparent
    public static func noop() {
        // This function will be optimized away
    }

    public static func sendError(_ message: String, file: String = #file, line: Int = #line) {
        UBNonFatalErrorReporter.report(NSError(domain: (file as NSString).lastPathComponent,
                                               code: line,
                                               userInfo: [NSDebugDescriptionErrorKey: message]))
    }
}
