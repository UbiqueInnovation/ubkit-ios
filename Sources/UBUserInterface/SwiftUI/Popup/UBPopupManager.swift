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

        private init() {}

        @Published var currentPopupContent: (() -> AnyView)?
        @Published var isPresented: Binding<Bool> = .constant(false)

        private var popupBindings: [String: Binding<Bool>] = [:]

        func showPopup(id: String, isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> AnyView) {
            popupBindings[id] = isPresented
            DispatchQueue.main.async {
                for (k, v) in self.popupBindings {
                    if k != id {
                        v.wrappedValue = false
                    }
                }
                self.currentPopupContent = content
                self.isPresented = isPresented
            }
        }
    }

#endif
