//
//  UIView+Autolayout.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - UIView Autolayout Extensions

extension UIView
{
    /// Sets contentHuggingPriority and contentCompressionResistance to highest priority both vertical and horizontal
    public func ub_contentPriorityRequired()
    {
        self.setContentHuggingPriority(.required, for: .horizontal)
        self.setContentHuggingPriority(.required, for: .vertical)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
