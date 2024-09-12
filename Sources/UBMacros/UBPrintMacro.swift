//
//  UBPrintMacro.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftParser
import os

public struct UBPrintMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        #if DEBUG
        guard node.argumentList.count == 1, let firstArgument = node.argumentList.first?.expression else {
            throw CustomError.message("Expected a single argument for #print")
        }
        return "UBPrintMacro.Logger.debug(\(firstArgument))"
        #elseif RELEASE
        return "UBPrintMacro.noop()"
        #else
        throw CustomError.message("Neither DEBUG or RELEASE is defined.")
        #endif
    }
}

public struct UBPrintErrorMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        guard node.argumentList.count == 1, let firstArgument = node.argumentList.first?.expression else {
            throw CustomError.message("Expected a single argument for #printError")
        }
        return "{UBPrintMacro.Logger.critical(\(firstArgument))\nUBPrintMacro.sendError(\(firstArgument))}()"

    }
}

public struct UBAssertMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        guard let firstArgument = node.argumentList.first?.expression
        else {
            throw CustomError.message("Expected at least one argument for #assert")
        }
        if node.argumentList.count > 1, let secondArgument = node.argumentList.last?.expression {
#if DEBUG
            return "{if !(\(firstArgument)) { UBPrintMacro.Logger.critical(\"Assertion failed: \\(\(secondArgument))\")\nSwift.assertionFailure() }}()"
#elseif RELEASE
            return "{if !(\(firstArgument)) { UBPrintMacro.Logger.critical(\"Assertion failed: \\(\(secondArgument))\")\nUBPrintMacro.sendError(\"Assertion failed: \" + \(secondArgument)) }}()"
#else
            throw CustomError.message("Neither DEBUG or RELEASE is defined.")
#endif
        }
        else {
#if DEBUG
            return "{if !(\(firstArgument)) { UBPrintMacro.Logger.critical(\"Assertion failed.\")\nSwift.assertionFailure() }}()"
#elseif RELEASE
            return "{if !(\(firstArgument)) { UBPrintMacro.Logger.critical(\"Assertion failed.\")\nUBPrintMacro.sendError(\"Assertion failed. \") }}()"
#else
            throw CustomError.message("Neither DEBUG or RELEASE is defined.")
#endif
        }
    }
}

public struct UBAssertionFailureMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        if let firstArgument = node.argumentList.first?.expression {
#if DEBUG
            return "{UBPrintMacro.Logger.critical(\"Assertion failed: \\(\(firstArgument))\")\nSwift.assertionFailure() }()"
#elseif RELEASE
            return "{UBPrintMacro.Logger.critical(\"Assertion failed: \\(\(firstArgument))\")\nUBPrintMacro.sendError(\"Assertion failed: \" + \(firstArgument)) }()"
#else
            throw CustomError.message("Neither DEBUG or RELEASE is defined.")
#endif
        }
        else {
#if DEBUG
            return "{UBPrintMacro.Logger.critical(\"Assertion failed.)\")\nSwift.assertionFailure() }()"
#elseif RELEASE
            return "{UBPrintMacro.Logger.critical(\"Assertion failed.\")\nUBPrintMacro.sendError(\"Assertion failed.\") }()"
#else
            throw CustomError.message("Neither DEBUG or RELEASE is defined.")
#endif
        }

    }
}
