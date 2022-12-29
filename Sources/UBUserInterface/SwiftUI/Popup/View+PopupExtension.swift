//
//  View+PopupExtension.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//
#if os(iOS) || os(tvOS) || os(watchOS)

#if arch(arm64) || arch(x86_64)

    import SwiftUI

    @available(iOS 14.0, *)
    public extension View {
        func ub_popup<V: View>(isPresented: Binding<Bool>, customStyle: UBPopupStyle? = nil, @ViewBuilder content: @escaping () -> V) -> some View {
            modifier(UBPopupViewModifier(isPresented: isPresented, customStyle: customStyle, popupContent: content))
        }
    }

    @available(iOS 14.0, *)
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
#endif
