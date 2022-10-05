//
//  UBPopupManager.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

    import Combine
    import SwiftUI

    @available(iOS 14.0, *)
    class UBPopupManager: ObservableObject {
        static let shared = UBPopupManager()

        private(set) var window: UIWindow?

        private init() {}

        var defaultStyle: UBPopupStyle = .init()

        private var currentPopupId: String?
        private(set) var currentPopupContent: (() -> AnyView)?
        private(set) var currentStyle: UBPopupStyle?

        @Published private(set) var isPresented: Bool = false

        private var isPresentedBinding: Binding<Bool> {
            .init {
                self.isPresented
            } set: { newValue in
                self.isPresented = newValue
                if !newValue {
                    if let id = self.currentPopupId, let binding = self.popupBindings[id] {
                        binding.wrappedValue = false
                    }
                    self.hideWindowIfNecessary()
                }
            }
        }

        private var popupBindings: [String: Binding<Bool>] = [:]

        func showPopup(id: String, isPresented: Binding<Bool>, customStyle: UBPopupStyle? = nil, @ViewBuilder content: @escaping () -> AnyView) {
            popupBindings[id] = isPresented
            DispatchQueue.main.async {
                for (k, v) in self.popupBindings {
                    if k != id {
                        v.wrappedValue = false
                    }
                }
                self.currentPopupId = id
                self.currentStyle = customStyle
                self.currentPopupContent = content
                self.isPresented = true
                self.window?.isUserInteractionEnabled = true
                self.window?.makeKey()
            }
        }

        func setupWindow() {
            guard window == nil else { return }

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                window = UIWindow(windowScene: scene)
                window?.windowLevel = .alert
                window?.backgroundColor = .clear
                window?.isUserInteractionEnabled = false
                window?.rootViewController = UIHostingController(rootView: UBPopupContainerView(isPresented: isPresentedBinding).environmentObject(self))
                window?.rootViewController?.view.backgroundColor = .clear
                window?.isHidden = false
            }
        }

        func hideWindowIfNecessary() {
            currentPopupId = nil
            currentStyle = nil
            currentPopupContent = nil
            if isPresented {
                isPresented = false
            }
            for binding in self.popupBindings.values {
                if binding.wrappedValue {
                    return
                }
            }
            window?.isUserInteractionEnabled = false
        }
    }

#endif
