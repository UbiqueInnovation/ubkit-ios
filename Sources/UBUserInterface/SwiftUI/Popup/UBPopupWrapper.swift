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

        let extendsToEdges: Bool
        let backgroundColor: Color
        let cornerRadius: CGFloat
        let insets: EdgeInsets
        let horizontalPadding: CGFloat
        let tapOutsideToDismiss: Bool
        @ViewBuilder let wrappedContent: () -> V

        public init(extendsToEdges: Bool = true,
                    backgroundColor: Color = .white,
                    cornerRadius: CGFloat = 15,
                    insets: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    horizontalPadding: CGFloat = 20,
                    tapOutsideToDismiss: Bool = true,
                    @ViewBuilder wrappedContent: @escaping () -> V) {
            self.extendsToEdges = extendsToEdges
            self.backgroundColor = backgroundColor
            self.cornerRadius = cornerRadius
            self.insets = insets
            self.horizontalPadding = horizontalPadding
            self.tapOutsideToDismiss = tapOutsideToDismiss
            self.wrappedContent = wrappedContent
        }

        public var body: some View {
            wrappedContent()
                .modifier(UBPopupViewModifier(isPresented: popupManager.isPresented,
                                              extendsToEdges: extendsToEdges,
                                              backgroundColor: backgroundColor,
                                              cornerRadius: cornerRadius,
                                              insets: insets,
                                              horizontalPadding: horizontalPadding,
                                              tapOutsideToDismiss: tapOutsideToDismiss) {
                        if let content = popupManager.currentPopupContent {
                            content()
                        }
                    })
        }
    }

#endif
