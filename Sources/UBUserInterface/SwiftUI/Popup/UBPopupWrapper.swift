//
//  UBPopupWrapper.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

    import Foundation
    import SwiftUI

    @available(iOS 14.0, *)
    public struct UBPopupWrapper<V: View>: View {
        @StateObject private var popupManager = UBPopupManager.shared

        let style: UBPopupStyle
        @ViewBuilder let wrappedContent: () -> V

        public init(style: UBPopupStyle = .init(), @ViewBuilder wrappedContent: @escaping () -> V) {
            self.style = style
            self.wrappedContent = wrappedContent
        }

        public var body: some View {
            wrappedContent()
                .onAppear {
                    popupManager.setupWindow()
                    popupManager.defaultStyle = style
                }
                .onChange(of: style) { newValue in
                    popupManager.defaultStyle = newValue
                }
        }
    }

#endif
