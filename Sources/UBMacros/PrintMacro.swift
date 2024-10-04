//
//  PrintMacro.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

import Foundation
import os
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PrintMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
#if DEBUG
        guard node.argumentList.count == 1, let firstArgument = node.argumentList.first?.expression else {
            throw CustomError.message("Expected a single argument for #print")
        }
        return "_PrintMacro.Logger.debug(\(firstArgument))"
#else
        return "_PrintMacro.noop()"
#endif
    }
}

public struct PrintErrorMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard node.argumentList.count == 1, let firstArgument = node.argumentList.first?.expression else {
            throw CustomError.message("Expected a single argument for #printError")
        }
        return "_PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\(firstArgument)))\")"
    }
}

public struct AssertMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard let firstArgument = node.argumentList.first?.expression
        else {
            throw CustomError.message("Expected at least one argument for #assert")
        }
        if node.argumentList.count > 1, let secondArgument = node.argumentList.last?.expression {
            return "_PrintMacro.assert(\(firstArgument),\n{ _PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\"Assertion failed:\" + \(secondArgument)))\") })"
        } else {
            return "_PrintMacro.assert(\(firstArgument),\n{ _PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\"Assertion failed.\"))\") })"
        }
    }
}

public struct AssertionFailureMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
        if let firstArgument = node.argumentList.first?.expression {
            "_PrintMacro.assertionFailure({ _PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\"Assertion failed:\" + \(firstArgument)))\") })"
        } else {
            "_PrintMacro.assertionFailure({ _PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\"Assertion failed.\"))\") })"
        }
    }
}
