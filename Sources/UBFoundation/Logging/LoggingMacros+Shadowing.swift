//
//  LoggingMacros+Shadowing.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

@available(*, message: "Use #print instead")
public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    Swift.print(items, separator: separator, terminator: terminator)
}

@available(*, message: "Use #assert instead")
public func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    Swift.assert(condition(), message(), file: file, line: line)
}

@available(*, message: "Use #assertionFailure instead")
public func assertionFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    Swift.assertionFailure(message(), file: file, line: line)
}

