//
//  UBPopupViewModifier.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

    import SwiftUI

    @available(iOS 14.0, *)
    struct UBPopupViewModifier<T: View>: ViewModifier {
        @Binding var isPresented: Bool
        let style: UBPopupStyle
        let popup: () -> T

        init(isPresented: Binding<Bool>,
             style: UBPopupStyle,
             @ViewBuilder content: @escaping () -> T) {
            self._isPresented = isPresented
            self.style = style
            self.popup = content
        }

        func body(content: Content) -> some View {
            content
                .overlay(popupContent())
        }

        @ViewBuilder private func popupContent() -> some View {
            ZStack {
                if isPresented {
                    VStack(alignment: .center) {
                        Spacer()
                        if style.extendsToEdges {
                            HStack {
                                Spacer()
                                popup()
                                    .padding(style.insets)
                                Spacer()
                            }
                            .background(style.backgroundColor)
                            .cornerRadius(style.cornerRadius)
                            .padding(style.horizontalPadding)
                        } else {
                            HStack {
                                Spacer()
                                popup()
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
