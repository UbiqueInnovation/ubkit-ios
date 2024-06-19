//
//  DevTools.swift
//
//
//  Created by Marco Zimmermann on 03.10.22.
//

import Foundation
import UIKit
import UBFoundation
import SwiftUI

protocol DevTool {
    static func setup()
}

@available(iOS 14.0, *)
public enum UBDevTools {
    static var isActivated: Bool = false

    private static let devTools: [DevTool.Type] = [FingerTipsDevTools.self, LocalizationDevTools.self, UIViewDevTools.self]

    public static func setup() {
        isActivated = true

        setupNavbarAppearance()

        UIWindow.sendInitSwizzleWizzle()

        for d in devTools {
            d.setup()
        }
    }

    public static func setAppSettingsView(view: some View) {
        BackendDevTools.setAppSettingsView(view: view)
    }

    public static func setupBaseUrls(baseUrls: [BaseUrl]) {
        BackendDevTools.setup(baseUrls: baseUrls)
    }

    public static func setupSharedUserDefaults(_ userDefaults: UserDefaults) {
        UserDefaultsDevTools.setupSharedUserDefaults(userDefaults)
    }

    public static func setupCaches(additional caches: [(id: String, cache: URLCache)]) {
        CacheDevTools.additionalCaches = caches
    }

    /// Sets a static proxy for networking debugging, if all requests should be proxied through a predefined proxy.
    ///
    /// This only works in combination with the `friendlySharedSession` as this proxy setup is used only there.
    /// Additionally you might want to set the `NSAllowsArbitraryLoads` flag in your `Info.plist`
    ///
    /// - Parameters:
    ///   - host: The host of your proxy, e.g. 'myproxy.ubique.ch'
    ///   - port: The port of your proxy, e.g. 8888
    ///   - username: Set the username if the proxy needs authorization
    ///   - password: Set the password if the proxy needs authorization
    public static func setupProxySettings(host: String, port: Int, username: String?, password: String?) {
        UBDevToolsProxyHelper.shared.setProxy(
            host: host, port: port, username: username, password: password
        )
    }

    // MARK: - Helper methods

    private static func setupNavbarAppearance() {
        UINavigationBar.appearance(whenContainedInInstancesOf: [DevToolsViewController.self]).isTranslucent = true
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.black,
        ]
        UINavigationBar.appearance(whenContainedInInstancesOf: [DevToolsViewController.self]).standardAppearance = appearance
        UINavigationBar.appearance(whenContainedInInstancesOf: [DevToolsViewController.self]).scrollEdgeAppearance = appearance
    }
}

@available(iOS 14.0, *)
extension UIWindow {
    private static var initSwizzled = false

    static func sendInitSwizzleWizzle() {
        guard !initSwizzled else { return }

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
        gr.cancelsTouchesInView = false
        gr.delaysTouchesBegan = false
        gr.delaysTouchesEnded = false
        window.addGestureRecognizer(gr)
        return window
    }

    @objc private func swizzed_frameInit(frame: CGRect) -> UIWindow {
        let window = swizzed_frameInit(frame: frame)
        let gr = UITapGestureRecognizer(target: self, action: #selector(openDevTools))
        gr.numberOfTapsRequired = 5
        gr.numberOfTouchesRequired = 2
        gr.cancelsTouchesInView = false
        gr.delaysTouchesBegan = false
        gr.delaysTouchesEnded = false
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
