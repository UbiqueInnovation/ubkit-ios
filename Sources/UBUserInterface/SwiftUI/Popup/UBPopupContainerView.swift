//
//  UBPopupContainerView.swift
//
//
//  Created by Matthias Felix on 05.10.22.
//

#if arch(arm64) || arch(x86_64)

    import SwiftUI

    @available(iOS 14.0, *)
    struct UBPopupContainerView: View {
        @EnvironmentObject private var popupManager: UBPopupManager

        @Binding var isPresented: Bool

        private var style: UBPopupStyle {
            popupManager.currentStyle ?? popupManager.defaultStyle
        }

        var body: some View {
            ZStack {
                if isPresented {
                    VStack(alignment: .center) {
                        Spacer()
                        if style.extendsToEdges {
                            HStack {
                                Spacer()
                                popupManager.currentPopupContent?()
                                    .padding(style.insets)
                                Spacer()
                            }
                            .background(style.backgroundColor)
                            .cornerRadius(style.cornerRadius)
                            .padding(style.horizontalPadding)
                        } else {
                            HStack {
                                Spacer()
                                popupManager.currentPopupContent?()
                                    .padding(style.insets)
                                    .background(style.backgroundColor)
                                    .cornerRadius(style.cornerRadius)
                                    .padding(style.horizontalPadding)
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .background(Color.black.opacity(0.8).onTapGesture {
                        if style.tapOutsideToDismiss {
                            isPresented = false
                        }
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .transition(.opacity)
            .animation(.default, value: isPresented)
        }
    }

#endif
