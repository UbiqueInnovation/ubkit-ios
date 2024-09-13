//
//  _PrintMacro.swift
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

public struct PrintMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        #if DEBUG
        guard node.argumentList.count == 1, let firstArgument = node.argumentList.first?.expression else {
            throw CustomError.message("Expected a single argument for #print")
        }
        return "_PrintMacro.Logger.debug(\(firstArgument))"
        #elseif RELEASE
        return "_PrintMacro.noop()"
        #else
        throw CustomError.message("Neither DEBUG or RELEASE is defined.")
        #endif
    }
}

public struct PrintErrorMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        guard node.argumentList.count == 1, let firstArgument = node.argumentList.first?.expression else {
            throw CustomError.message("Expected a single argument for #printError")
        }
        return "_PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\(firstArgument)))\")"

    }
}

public struct AssertMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        guard let firstArgument = node.argumentList.first?.expression
        else {
            throw CustomError.message("Expected at least one argument for #assert")
        }
        if node.argumentList.count > 1, let secondArgument = node.argumentList.last?.expression {
            return "_PrintMacro.assert(\(firstArgument),\n{ _PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\"Assertion failed:\" + \(secondArgument)))\") })"
        }
        else {
            return "_PrintMacro.assert(\(firstArgument),\n{ _PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\"Assertion failed.\"))\") })"
        }
    }
}

public struct AssertionFailureMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        if let firstArgument = node.argumentList.first?.expression {
            return "_PrintMacro.assertionFailure({ _PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\"Assertion failed:\" + \(firstArgument)))\") })"
        }
        else {
            return "_PrintMacro.assertionFailure({ _PrintMacro.Logger.critical(\"\\(_PrintMacro.sendError(\"Assertion failed.\"))\") })"
        }

    }
}
