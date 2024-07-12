//
//  FingerTipsDevTools.swift
//
//
//  Created by Marco Zimmermann on 30.09.22.
//

import UBFoundation
import UIKit

class FingerTipsDevTools: DevTool {
    private static var overlayWindow: FingerTipsWindow?
    private static var notificationHelper: NotificationHelper?

    static func setup() {
        let nh = NotificationHelper()
        NotificationCenter.default.addObserver(nh, selector: #selector(nh.setupFingerTips), name: UIWindow.didBecomeKeyNotification, object: nil)
        Self.notificationHelper = nh
    }

    @objc static func setupFingerTips() {
        let show = DevToolsView.showFingerTips
        Self.showFingerTips(show)
    }

    // MARK: - Window setup

    static func showFingerTips(_ showFingerTips: Bool) {
        if showFingerTips {
            if let currentWindowScene = UIApplication.shared.connectedScenes.first {
                overlayWindow = FingerTipsWindow(windowScene: currentWindowScene as! UIWindowScene)
                overlayWindow?.windowLevel = UIWindow.Level.alert
                overlayWindow?.isUserInteractionEnabled = false
                UIWindow.sendEventSwizzleWizzle()
                overlayWindow?.isHidden = false
                overlayWindow?.rootViewController = UIViewController()
                setMainAssociatedObject(overlayWindow)
            }
        } else {
            setMainAssociatedObject(nil)
            overlayWindow?.remove()
            overlayWindow = nil
        }
    }

    // MARK: - Helper

    private static func setMainAssociatedObject(_ window: UIWindow?) {
        if let main = UIApplication.shared.windows.first(where: {
            !($0 is FingerTipsWindow)
        }) {
            objc_setAssociatedObject(main, &UIWindow.associatedObjectHandle, window, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

private class NotificationHelper {
    @MainActor
    @objc public func setupFingerTips() {
        FingerTipsDevTools.setupFingerTips()
        NotificationCenter.default.removeObserver(self)
    }
}
