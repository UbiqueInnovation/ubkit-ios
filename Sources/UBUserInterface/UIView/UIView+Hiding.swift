//
//  UIView+Hiding.swift
//
//
//  Created by Zeno Koller on 13.05.22.
//

import UIKit

public extension UIView {
    /// fixes https://github.com/nkukushkin/StackView-Hiding-With-Animation-Bug-Example
    func ub_setHidden(_ hidden: Bool) {
        if isHidden != hidden {
            isHidden = hidden
            alpha = hidden ? 0.0 : 1.0
        }
    }
}
