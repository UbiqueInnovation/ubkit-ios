//
//  KeyboardLayoutGuide+UIKit.swift
//  UBFoundation iOS
//
//  Created by Joseph El Mallah on 17.05.19.
//

import UIKit

extension UIView {
    /// The layout guide representing the portion of your view that is obscured by the keyboard.
    ///
    /// When the view is visible onscreen, this guide reflects the portion of the view that is covered by the keyboard. If the view is not currently installed in a view hierarchy, or is not yet visible onscreen, the layout guide edges are equal to the edges of the view.
    ///
    public var keyboardLayoutGuide: UILayoutGuide {
        if let existingGuide = self.layoutGuides.first(where: { $0 is ViewKeyboardLayoutGuide }) {
            return existingGuide
        }

        let guide = ViewKeyboardLayoutGuide()
        addLayoutGuide(guide)

        return guide
    }
}

extension UIWindow {
    public func initializeForKeyboardLayoutGuide() {
        guard layoutGuides.contains(where: { $0 is WindowKeyboardLayoutGuide }) == false else {
            return
        }
        let guide = WindowKeyboardLayoutGuide()
        addLayoutGuide(guide)
    }

    var windowKeyboardLayoutGuide: UILayoutGuide? {
        return layoutGuides.first(where: { $0 is WindowKeyboardLayoutGuide })
    }
}
