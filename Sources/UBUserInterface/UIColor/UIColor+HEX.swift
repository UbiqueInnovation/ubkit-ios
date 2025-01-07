//
//  UIColor+HEX.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 25.03.19.
//

import UIKit

/// Some code was inspiered by https://github.com/yeahdongcn/UIColor-Hex-Swift

// MARK: - HEX manipulation of UIColor

extension UIColor {
    /// :nodoc:
    private convenience init(hex3: UInt16) {
        let divisor = CGFloat(0xF)
        let red = CGFloat((hex3 & 0xF00) >> 8) / divisor
        let green = CGFloat((hex3 & 0x0F0) >> 4) / divisor
        let blue = CGFloat(hex3 & 0x00F) / divisor
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    /// :nodoc:
    private convenience init(hex4: UInt16) {
        let divisor = CGFloat(0xF)
        let red = CGFloat((hex4 & 0xF000) >> 12) / divisor
        let green = CGFloat((hex4 & 0x0F00) >> 8) / divisor
        let blue = CGFloat((hex4 & 0x00F0) >> 4) / divisor
        let alpha = CGFloat(hex4 & 0x000F) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// :nodoc:
    private convenience init(hex6: UInt32) {
        let divisor = CGFloat(0xFF)
        let red = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green = CGFloat((hex6 & 0x00FF00) >> 8) / divisor
        let blue = CGFloat(hex6 & 0x0000FF) / divisor
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    /// :nodoc:
    private convenience init(hex8: UInt32) {
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
    public convenience init?(ub_hexString hex: String) {
        let input = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove optional '#' prefix
        let hexString = input.hasPrefix("#") ? String(input.dropFirst()) : input

        // Validate length (3, 4, 6, or 8)
        guard [3, 4, 6, 8].contains(hexString.count),
              hexString.allSatisfy({ $0.isHexDigit }) else {
            return nil
        }

        var hexValue: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&hexValue) else {
            return nil
        }

        switch hexString.count {
            case 3:
                self.init(hex3: UInt16(hexValue))
            case 4:
                self.init(hex4: UInt16(hexValue))
            case 6:
                self.init(hex6: UInt32(hexValue))
            case 8:
                self.init(hex8: UInt32(hexValue))
            default:
                fatalError("Unexpected hex string length. This should not occur.")
        }
    }

    /// Renders the color as a hex string
    ///
    /// This function will always return a format of 6 HEX: __#DEF212__ or if with alpha, a format of 8 HEX __#DECA23FF__
    ///
    /// - Note: Only available for iOS, watchOS and tvOS
    ///
    /// - Returns: A HEX string representing the color
    public var ub_hexString: String? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)

        guard r >= 0, r <= 1, g >= 0, g <= 1, b >= 0, b <= 1 else {
            return nil
        }

        guard a != 1 else {
            return String(format: "#%02X%02X%02X", Int(r * 0xFF), Int(g * 0xFF), Int(b * 0xFF))
        }

        return String(format: "#%02X%02X%02X%02X", Int(r * 0xFF), Int(g * 0xFF), Int(b * 0xFF), Int(a * 0xFF))
    }
}
