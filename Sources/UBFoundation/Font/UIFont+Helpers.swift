//
//  UIFont+Helpers.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//


#if os(iOS) || os(tvOS)
import UIKit

// MARK: - UIFont Helpers

extension UIFont {
    /// Returns the height of the font
    public func ub_fontHeight() -> CGFloat {
        return ascender - descender
    }
}
#endif
