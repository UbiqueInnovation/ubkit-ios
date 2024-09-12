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

public struct UBPrintMacroDebug: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        guard let firstArgument = node.argumentList.first?.expression else {
            throw CustomError.message("Expected a single argument for #print")
        }
        return "UBPrintMacro.Logger.debug(\(firstArgument))"
    }
}

public struct UBPrintMacroRelease: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        return "UBPrintMacro.noop()"

    }
}

public struct UBPrintErrorMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        guard let firstArgument = node.argumentList.first?.expression else {
            throw CustomError.message("Expected a single argument for #print")
        }
        return "{UBPrintMacro.Logger.critical(\(firstArgument))\nUBPrintMacro.sendError(\(firstArgument))}()"

    }
}
