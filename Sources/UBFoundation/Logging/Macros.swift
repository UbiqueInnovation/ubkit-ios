//
//  Macros.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

import Foundation
import os

#if DEBUG
@available(iOS 14.0, *)
@freestanding(expression)
public macro print(_ message: OSLogMessage) = #externalMacro(
    module: "UBMacros",
    type: "UBPrintMacroDebug"
)
#else
@available(iOS 14.0, *)
@freestanding(expression)
public macro print(_ message: OSLogMessage) = #externalMacro(
    module: "UBMacros",
    type: "UBPrintMacroRelease"
)
#endif

@available(iOS 14.0, *)
@freestanding(expression)
public macro printError(_ message: OSLogMessage) = #externalMacro(
    module: "UBMacros",
    type: "UBPrintErrorMacro"
)

@available(iOS 14.0, *)
public struct UBPrintMacro {
    public static let Logger = os.Logger(subsystem: "UBLog", category: "Default")

    @_transparent
    public static func noop() {
        // This function will be optimized away
    }

    public static var errorCallback: ((String) -> Void)?

    public static func sendError(_ message: String) {
        self.errorCallback?(message)
    }
}
