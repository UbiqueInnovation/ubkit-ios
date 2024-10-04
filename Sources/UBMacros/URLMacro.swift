//
//  URLMacro.swift
//
//
//  Created by Matthias Felix on 20.09.2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct URLMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression,
              let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
              segments.count == 1,
              case let .stringSegment(literalSegment) = segments.first else {
            throw CustomError.message("#URL requires a static string literal")
        }

        guard let _ = URL(string: literalSegment.content.text) else {
            throw CustomError.message("Malformed url: \(argument)")
        }

        return "URL(string: \(argument))!"
    }
}
