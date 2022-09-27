//
//  View+PopupExtension.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

    import SwiftUI

    @available(iOS 14.0, *)
    public extension View {
        func ub_popup<V: View>(id: String, isPresented: Binding<Bool>, customStyle: UBPopupStyle? = nil, @ViewBuilder _ content: @escaping () -> V) -> some View {
            self
                .onChange(of: isPresented.wrappedValue) { newValue in
                    if newValue {
                        UBPopupManager.shared.showPopup(id: id, isPresented: isPresented, customStyle: customStyle, content: { AnyView(content()) })
                    }
                }
        }
    }

#endif
