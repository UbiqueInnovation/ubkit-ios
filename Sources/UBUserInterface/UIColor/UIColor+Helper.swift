//
//  UIColor+Helper.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - General helpers for UIColor

public extension UIColor {
    /// Color interpolation
    /// - Returns: Color as interpolation (self*firstFactor + color*(1.0-firstFactor)
    func ub_colorByInterpolating(with color: UIColor, firstFactor: CGFloat) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let f1 = firstFactor
        let f2 = (1.0 - f1)

        let r = f1 * r1 + f2 * r2
        let g = f1 * g1 + f2 * g2
        let b = f1 * b1 + f2 * b2
        let a = f1 * a1 + f2 * a2

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    /// Color multiplication
    /// - Returns: Color multiplyed by color
    func ub_colorByMultiplying(with color: UIColor) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let otherAlpha: CGFloat = a2
        let oneMinus = (1.0 - a2)

        let r = r1 * r2 * otherAlpha + oneMinus * r1
        let g = g1 * g2 * otherAlpha + oneMinus * g1
        let b = b1 * b2 * otherAlpha + oneMinus * b1
        let a = a1 * a2 * otherAlpha + oneMinus * a1

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
