//
//  UIView+Autolayout.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - UIView Autolayout Extensions

extension UIView {
    /// Sets contentHuggingPriority and contentCompressionResistance to highest priority both vertical and horizontal
    public func ub_setContentPriorityRequired() {
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
