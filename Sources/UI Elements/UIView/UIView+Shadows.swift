//
//  UIView+Shadows.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - UIView Shadow Extensions

extension UIView
{
    /// Adds shadow to UIView with black color and other parameters
    public func ub_addShadow(with radius : CGFloat, opacity: CGFloat, xOffset: CGFloat, yOffset: CGFloat)
    {
        self.ub_addShadow(with: UIColor.black, radius: radius, opacity: opacity, xOffset: xOffset, yOffset: yOffset)
    }

    /// Adds shadow to UIView with color and other parameters
    public func ub_addShadow(with color: UIColor, radius : CGFloat, opacity: CGFloat, xOffset: CGFloat, yOffset: CGFloat)
    {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = Float(opacity)
        self.layer.shadowOffset = CGSize(width: xOffset, height: yOffset)
        self.layer.shadowRadius = radius
        self.layer.masksToBounds = false
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
}
