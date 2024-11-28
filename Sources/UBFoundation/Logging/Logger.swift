//
//  Logger.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

// LOGGER TEMPLATE FILE
// Copy this file to your project, replace subsystem and category with your own values
// Copying ensures that methods shadow Swift originals

import Foundation
import os

public let Log = os.Logger(subsystem: "UBKit", category: "Default")

public extension Logger {
    func reportError(
        _ message: String, file: StaticString = #file, line: UInt = #line
    ) {
        UBNonFatalErrorReporter.shared
            .report(
                NSError(
                    domain: (file.description as NSString).lastPathComponent,
                    code: Int(line),
                    userInfo: [NSDebugDescriptionErrorKey: message]
                )
            )
        Log.error("\(message)")
    }

    func reportCritical(
        _ message: String, file: StaticString = #file, line: UInt = #line
    ) {
        UBNonFatalErrorReporter.shared
            .report(
                NSError(
                    domain: (file.description as NSString).lastPathComponent,
                    code: Int(line),
                    userInfo: [NSDebugDescriptionErrorKey: message]
                )
            )
        Log.critical("\(message)")
    }
}

@available(*, deprecated, message: "Use Logger instead", renamed: "Log.debug")
public func print(
    _ items: Any..., separator: String = " ", terminator: String = "\n"
) {
    Log.debug("(\(items.map { "\($0)" }.joined(separator: separator)))")
}

public func assert(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = String(),
    swiftAssertionFailure: Bool = true,
    file: StaticString = #file,
    line: UInt = #line
) {
    if !condition() {
        Log.reportCritical(message(), file: file, line: line)
        if swiftAssertionFailure {
            Swift.assertionFailure()
        }
    }
}

public func assertionFailure(
    _ message: @autoclosure () -> String = String(),
    swiftAssertionFailure: Bool = true,
    file: StaticString = #file,
    line: UInt = #line
) {
    Log.reportCritical("Assertion failed: \(message())")
    if swiftAssertionFailure {
        Swift.assertionFailure(message(), file: file, line: line)
    }
}
