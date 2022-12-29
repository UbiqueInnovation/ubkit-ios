//
//  UIFont+Helpers.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit

    // MARK: - UIFont Helpers

    public extension UIFont {
        /// Returns the height of the font
        func ub_fontHeight() -> CGFloat {
            ascender - descender
        }
    }
#endif
