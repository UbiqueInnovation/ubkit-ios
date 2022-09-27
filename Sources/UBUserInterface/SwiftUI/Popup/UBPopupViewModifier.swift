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
        let extendsToEdges: Bool
        let backgroundColor: Color
        let cornerRadius: CGFloat
        let insets: EdgeInsets
        let horizontalPadding: CGFloat
        let tapOutsideToDismiss: Bool
        let popup: () -> T

        init(isPresented: Binding<Bool>,
             extendsToEdges: Bool,
             backgroundColor: Color,
             cornerRadius: CGFloat,
             insets: EdgeInsets,
             horizontalPadding: CGFloat,
             tapOutsideToDismiss: Bool,
             @ViewBuilder content: @escaping () -> T) {
            self._isPresented = isPresented
            self.extendsToEdges = extendsToEdges
            self.backgroundColor = backgroundColor
            self.cornerRadius = cornerRadius
            self.insets = insets
            self.horizontalPadding = horizontalPadding
            self.tapOutsideToDismiss = tapOutsideToDismiss
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
                        if extendsToEdges {
                            HStack {
                                Spacer()
                                popup()
                                    .padding(insets)
                                Spacer()
                            }
                            .background(backgroundColor)
                            .cornerRadius(cornerRadius)
                            .padding(horizontalPadding)
                        } else {
                            HStack {
                                Spacer()
                                popup()
                                    .padding(insets)
                                    .background(backgroundColor)
                                    .cornerRadius(cornerRadius)
                                    .padding(horizontalPadding)
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .background(Color.black.opacity(0.8).onTapGesture {
                        if tapOutsideToDismiss {
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
