//
//  UIView+Shadows.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - UIView Shadow Extensions

public extension UIView {
    /// Adds shadow to UIView with black color and other parameters
    func ub_addShadow(with color: UIColor = UIColor.black, radius: CGFloat, opacity: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = Float(opacity)
        layer.shadowOffset = CGSize(width: xOffset, height: yOffset)
        layer.shadowRadius = radius
        layer.masksToBounds = false
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
}
