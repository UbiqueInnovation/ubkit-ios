//
//  UIImage+Helpers.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - UIImage Helpers

public extension UIImage {
    /// Initializes an image with a single pixel with a constant color
    static func ub_singlePixelImage(with color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)

        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
    }

    /// Create a tinted version of the image with the specified color
    func ub_withColor(_ color: UIColor) -> UIImage {
        if #available(iOS 13.0, *) {
            return withTintColor(color)
        } else {
            let opaque: Bool

            if let alpha = cgImage?.alphaInfo {
                opaque = alpha == .none || alpha == .noneSkipFirst || alpha == .noneSkipLast
            } else {
                opaque = true
            }

            UIGraphicsBeginImageContextWithOptions(size, opaque, scale)

            guard let context = UIGraphicsGetCurrentContext(), let img = cgImage else { return self }

            color.setFill()

            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1, y: -1)
            context.setBlendMode(.colorBurn)

            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            context.draw(img, in: rect)

            context.setBlendMode(.sourceIn)
            context.addRect(rect)
            context.drawPath(using: .fill)

            let result = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()

            return result ?? self
        }
    }
}
