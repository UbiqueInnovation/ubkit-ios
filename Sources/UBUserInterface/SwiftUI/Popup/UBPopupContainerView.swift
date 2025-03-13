//
//  UBPopupContainerView.swift
//
//
//  Created by Matthias Felix on 05.10.22.
//

#if arch(arm64) || arch(x86_64)

    import SwiftUI

    struct UBPopupContainerView: View {
        @Binding var isPresented: Bool
        let style: UBPopupStyle
        let content: () -> AnyView

        var body: some View {
            ZStack {
                if isPresented {
                    VStack(alignment: .center) {
                        Spacer()
                        if style.extendsToEdges {
                            HStack {
                                Spacer()
                                content()
                                    .padding(style.insets)
                                Spacer()
                            }
                            .background(style.backgroundColor)
                            .cornerRadius(style.cornerRadius)
                            .padding(style.horizontalPadding)
                        } else {
                            HStack {
                                Spacer()
                                content()
                                    .padding(style.insets)
                                    .background(style.backgroundColor)
                                    .cornerRadius(style.cornerRadius)
                                    .padding(style.horizontalPadding)
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .background(
                        style.backdropColor.onTapGesture {
                            if style.tapOutsideToDismiss {
                                isPresented = false
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .transition(.opacity)
            .animation(.default, value: isPresented)
        }
    }

#endif
