//
//  LoggingMacros+Shadowing.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

import Foundation
import os

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public struct _PrintMacro {
    public static let Logger = os.Logger(subsystem: "UBLog", category: "Default")

    @_transparent
    public static func noop() {
        // This function will be optimized away
    }

    // Assertion Failure can be disabled
    // Useful for unit tests to avoid crash
    public static var disableAssertionFailure = false

    public static func sendError(_ message: String, file: String = #file, line: Int = #line) -> String {
        UBNonFatalErrorReporter.report(NSError(domain: (file as NSString).lastPathComponent,
                                               code: line,
                                               userInfo: [NSDebugDescriptionErrorKey: message]))
        return message // allows nesting sendError ins os_log statements
    }

    public static func assert(_ condition: Bool, _ handler: ()->Void) {
        if !condition {
            handler()
            if !Self.disableAssertionFailure {
                Swift.assertionFailure()
            }
        }
    }

    public static func assertionFailure(_ handler: ()->Void) {
        handler()
        if !Self.disableAssertionFailure {
            Swift.assertionFailure()
        }
    }
}

