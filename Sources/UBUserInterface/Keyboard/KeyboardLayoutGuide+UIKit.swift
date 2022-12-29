//
//  KeyboardLayoutGuide+UIKit.swift
//  UBFoundation iOS
//
//  Created by Joseph El Mallah on 17.05.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public extension UIView {
    /// The layout guide representing the portion of your view that is obscured by the keyboard.
    ///
    /// When the view is visible onscreen, this guide reflects the portion of the view that is covered by the keyboard. If the view is not currently installed in a view hierarchy, or is not yet visible onscreen, the layout guide edges are equal to the edges of the view.
    /// - Note: It is necessary to call `initializeForKeyboardLayoutGuide()` on `UIWindow` at the launch of the app in order to instanciate the listening correctly. Failing to do so will crash the app.
    var ub_keyboardLayoutGuide: UILayoutGuide {
        if let existingGuide = layoutGuides.first(where: { $0 is ViewKeyboardLayoutGuide }) {
            return existingGuide
        }

        let guide = ViewKeyboardLayoutGuide()
        addLayoutGuide(guide)

        return guide
    }
}

extension UIWindow {
    /// Call this function at the launch of the app in order to setup the monitoring of the keyboard on the Window/
    public func initializeForKeyboardLayoutGuide() {
        guard layoutGuides.contains(where: { $0 is WindowKeyboardLayoutGuide }) == false else {
            return
        }
        let guide = WindowKeyboardLayoutGuide()
        addLayoutGuide(guide)
    }

    /// Get the keyboard layout guide
    var windowKeyboardLayoutGuide: UILayoutGuide? {
        layoutGuides.first(where: { $0 is WindowKeyboardLayoutGuide })
    }
}
#endif
