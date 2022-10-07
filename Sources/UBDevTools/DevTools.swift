//
//  DevTools.swift
//
//
//  Created by Marco Zimmermann on 03.10.22.
//

import Foundation
import UIKit

protocol DevTool {
    static func setup()
}

@available(iOS 13.0, *)
public enum UBDevTools {
    static var isActivated: Bool = false

    private static let devTools: [DevTool.Type] = [FingerTipsDevTools.self, LocalizationDevTools.self, UIViewDevTools.self]

    public static func setup() {
        Self.isActivated = true

        UIWindow.sendInitSwizzleWizzle()

        for d in devTools {
            d.setup()
        }
    }

    public static func setupBaseUrls(baseUrls: [BaseUrl]) {
        BackendDevTools.setup(baseUrls: baseUrls)
    }

    public static func setupSharedUserDefaults(_ userDefaults: UserDefaults) {
        UserDefaultsDevTools.setupSharedUserDefaults(userDefaults)
    }
}

@available(iOS 13.0, *)
extension UIWindow {
    private static var initSwizzled = false

    static func sendInitSwizzleWizzle() {
        guard !Self.initSwizzled else { return }

        if let originalMethod = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.init(windowScene:))),
           let swizzledMethod = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.swizzled_windowSceneInit)) {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

        if let originalMethod = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.init(frame:))),
           let swizzledMethod = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.swizzed_frameInit(frame:))) {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

        Self.initSwizzled = true
    }

    @objc private func swizzled_windowSceneInit(windowScene: UIWindowScene) -> UIWindow {
        let window = swizzled_windowSceneInit(windowScene: windowScene)
        let gr = UITapGestureRecognizer(target: self, action: #selector(openDevTools))
        gr.numberOfTapsRequired = 5
        gr.numberOfTouchesRequired = 2
        window.addGestureRecognizer(gr)
        return window
    }

    @objc private func swizzed_frameInit(frame: CGRect) -> UIWindow {
        let window = swizzed_frameInit(frame: frame)
        let gr = UITapGestureRecognizer(target: self, action: #selector(openDevTools))
        gr.numberOfTapsRequired = 5
        gr.numberOfTouchesRequired = 2
        window.addGestureRecognizer(gr)
        return window
    }

    @objc private func openDevTools() {
        if let rootVC = rootViewController, let devToolsVC = DevToolsViewController() {
            var vc = rootVC
            while let presented = vc.presentedViewController {
                vc = presented
            }

            guard !(vc is DevToolsViewController) else { return } // Prevent multiple presented DevTools

            vc.present(devToolsVC, animated: true)
        }
    }
}
