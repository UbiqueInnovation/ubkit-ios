//
//  UIColorMacro.swift
//  
//
//  Created by Matthias Felix on 20.09.2023.
//


import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
#if canImport(UIKit)
import UIKit
#endif

public struct UIColorMacro: ExpressionMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> ExprSyntax where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {

        guard let argument = node.argumentList.first?.expression,
              let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
              segments.count == 1,
              case .stringSegment(let literalSegment) = segments.first else {
            throw CustomError.message("#UIColor requires a static string literal")
        }

        guard let _ = UIColor(ub_hexString: literalSegment.content.text) else {
            throw CustomError.message("Malformed hex color literal: \(argument)")
        }

        return "UIColor(ub_hexString: \(argument))!"
    }
}

// MARK: - Boilerplate code needed to check validity

private extension UIColor {
    /// :nodoc:
    convenience init(hex3: UInt16) {
        let divisor = CGFloat(0xF)
        let red = CGFloat((hex3 & 0xF00) >> 8) / divisor
        let green = CGFloat((hex3 & 0x0F0) >> 4) / divisor
        let blue = CGFloat(hex3 & 0x00F) / divisor
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    /// :nodoc:
    convenience init(hex4: UInt16) {
        let divisor = CGFloat(0xF)
        let red = CGFloat((hex4 & 0xF000) >> 12) / divisor
        let green = CGFloat((hex4 & 0x0F00) >> 8) / divisor
        let blue = CGFloat((hex4 & 0x00F0) >> 4) / divisor
        let alpha = CGFloat(hex4 & 0x000F) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// :nodoc:
    convenience init(hex6: UInt32) {
        let divisor = CGFloat(0xFF)
        let red = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green = CGFloat((hex6 & 0x00FF00) >> 8) / divisor
        let blue = CGFloat(hex6 & 0x0000FF) / divisor
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    /// :nodoc:
    convenience init(hex8: UInt32) {
        let divisor = CGFloat(0xFF)
        let red = CGFloat((hex8 & 0xFF00_0000) >> 24) / divisor
        let green = CGFloat((hex8 & 0x00FF_0000) >> 16) / divisor
        let blue = CGFloat((hex8 & 0x0000_FF00) >> 8) / divisor
        let alpha = CGFloat(hex8 & 0x0000_00FF) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Initializes a color from a HEX string
    ///
    /// This function can take as input 3 Hex Color: __#F2B__, 4 Hex Color with alpha channel: __#F2B3__, 6 HEX: __#FFED12__ or 8 HEX with alpha channel: __#FF00FFAA__. The __#__ is optional.
    ///
    /// - Note: Only available for iOS, watchOS and tvOS
    ///
    /// - Parameter hex: The raw hex string
    convenience init?(ub_hexString hex: String) {
        let input = hex.trimmingCharacters(in: .whitespaces)
        // We want to crash if the regex cannot be formed. Error from the Framework that needs an update
        let hexStringRegex = try! NSRegularExpression(pattern: "^\\#?([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$", options: .caseInsensitive)

        guard let hexStringResult = hexStringRegex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }

        guard hexStringResult.numberOfRanges == 2,
              let hexCapturedRange = Range(hexStringResult.range(at: 1), in: input) else {
            return nil
        }

        let hexString = String(input[hexCapturedRange])
        var hexValue: UInt32 = 0

        guard Scanner(string: hexString).scanHexInt32(&hexValue) else {
            return nil
        }

        switch hexString.count {
            case 3:
                self.init(hex3: UInt16(hexValue))
            case 4:
                self.init(hex4: UInt16(hexValue))
            case 6:
                self.init(hex6: hexValue)
            case 8:
                self.init(hex8: hexValue)
            default:
                fatalError("Should not be able to get other then 3-4-6-8 hex. Check regex")
        }
    }
}
