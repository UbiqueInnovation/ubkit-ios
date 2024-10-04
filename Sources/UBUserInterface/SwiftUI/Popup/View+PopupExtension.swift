//
//  View+PopupExtension.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

import SwiftUI

public extension View {
    func ub_popup(isPresented: Binding<Bool>, customStyle: UBPopupStyle? = nil, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(UBPopupViewModifier(isPresented: isPresented, customStyle: customStyle, popupContent: content))
    }
}

struct UBPopupViewModifier<V: View>: ViewModifier {
    @State private var date: Date?
    @Binding var isPresented: Bool
    let customStyle: UBPopupStyle?
    @ViewBuilder let popupContent: () -> V

    func body(content: Content) -> some View {
        content
            .preference(key: UBPopupPreferenceKey.self, value: UBPopupPreference(isPresented: $isPresented,
                                                                                 date: date,
                                                                                 customStyle: customStyle,
                                                                                 content: { AnyView(popupContent()) }))
            .onChange(of: isPresented) { date = $0 ? Date() : nil }
    }
}

#endif
