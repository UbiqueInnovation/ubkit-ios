//
//  UBPopupWindowManager.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

import Combine
import SwiftUI

@available(iOS 14.0, *)
class UBPopupWindowManager {
    static let shared = UBPopupWindowManager()

    private(set) var window: UIWindow?

    private(set) lazy var hostingController = UIHostingController(rootView: UBPopupContainerView(isPresented: .constant(false), style: .init(), content: { AnyView(EmptyView()) }))

    private init() {}

    func showPopup(isPresented: Binding<Bool>, style: UBPopupStyle, @ViewBuilder content: @escaping () -> AnyView) {
        window?.isUserInteractionEnabled = true
        window?.makeKey()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.hostingController.rootView = UBPopupContainerView(isPresented: isPresented, style: style, content: content)
        }
    }

    func setupWindow() {
        guard window == nil else { return }

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            window = UIWindow(windowScene: scene)
            window?.windowLevel = .alert
            window?.backgroundColor = .clear
            window?.isUserInteractionEnabled = false
            window?.rootViewController = hostingController
            window?.rootViewController?.view.backgroundColor = .clear
            window?.isHidden = false
        }
    }

    func hideWindow() {
        window?.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.hostingController.rootView = UBPopupContainerView(isPresented: .constant(false), style: .init(), content: { AnyView(EmptyView()) })
        }
    }
}

#endif
