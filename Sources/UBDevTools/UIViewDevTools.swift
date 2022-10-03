//
//  UIViewDevTools.swift
//  
//
//  Created by Marco Zimmermann on 03.10.22.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
class UIViewDevTools : DevTool {
    static func setup() {
        if DevToolsView.showViewBorders {
            UIView.layoutSwizzleWizzle()
        }
    }
}

extension UIView {
    static var layoutSubviewSwizzled = false

    static func layoutSwizzleWizzle() {
        guard let originalMethod = class_getInstanceMethod(UIView.self, #selector(layoutSubviews)), let swizzledMethod = class_getInstanceMethod(UIView.self, #selector(swizzled_layoutSubviews)), !Self.layoutSubviewSwizzled
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
        Self.layoutSubviewSwizzled = true
    }

    @objc func swizzled_layoutSubviews() {
        swizzled_layoutSubviews()
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.green.cgColor
    }
}
