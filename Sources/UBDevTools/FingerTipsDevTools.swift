//
//  FingerTipsDevTools.swift
//  
//
//  Created by Marco Zimmermann on 30.09.22.
//

import UIKit

@available(iOS 13.0, *)
class FingerTipsDevTools {
    static private var overlayWindow : FingerTipsWindow?

    static func showFingerTips(_ showFingerTips: Bool) {
        if showFingerTips {
            if let currentWindowScene = UIApplication.shared.connectedScenes.first {
                overlayWindow = FingerTipsWindow(windowScene: currentWindowScene as! UIWindowScene)
                overlayWindow?.windowLevel = UIWindow.Level.alert
                overlayWindow?.isUserInteractionEnabled = false
                Self.setMainAssociatedObject(overlayWindow)
                UIWindow.sendEventSwizzleWizzle()
                overlayWindow?.isHidden = false
            }
        } else {
            Self.setMainAssociatedObject(nil)
            overlayWindow?.remove()
            overlayWindow = nil
        }
    }

    static func setMainAssociatedObject(_ window: UIWindow?) {
        if let main = UIApplication.shared.windows.first(where: {
            !($0 is FingerTipsWindow) }) {
            objc_setAssociatedObject(main, &UIWindow.associatedObjectHandle, window, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
