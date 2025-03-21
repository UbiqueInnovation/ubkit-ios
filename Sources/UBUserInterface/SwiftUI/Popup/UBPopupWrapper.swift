//
//  UBPopupWrapper.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

    import Foundation
    import UBFoundation
    import SwiftUI

    public struct UBPopupWrapper<V: View>: View {
        let style: UBPopupStyle
        @ViewBuilder let wrappedContent: () -> V

        public init(style: UBPopupStyle = .init(), @ViewBuilder wrappedContent: @escaping () -> V) {
            self.style = style
            self.wrappedContent = wrappedContent
        }

        public var body: some View {
            wrappedContent()
                .onAppear {
                    UBPopupWindowManager.shared.setupWindow()
                }
                .onPreferenceChange(UBPopupPreferenceKey.self) { popupPreference in
                    if Thread.isMainThread {
                        MainActor.assumeIsolated {
                            popupPreferenceChanged(popupPreference: popupPreference)
                        }
                    } else {
                        Log.reportError("onPreferenceChange called on non-main thread")
                        DispatchQueue.main.async {
                            MainActor.assumeIsolated {
                                popupPreferenceChanged(popupPreference: popupPreference)
                            }
                        }
                    }
                }
        }

        private func popupPreferenceChanged(popupPreference: UBPopupPreference?) {
            if let popupPreference, popupPreference.isPresented.wrappedValue {
                UBPopupWindowManager.shared.showPopup(isPresented: popupPreference.isPresented, style: popupPreference.customStyle ?? style, content: popupPreference.content)
            } else {
                UBPopupWindowManager.shared.hideWindow()
            }
        }
    }

#endif
