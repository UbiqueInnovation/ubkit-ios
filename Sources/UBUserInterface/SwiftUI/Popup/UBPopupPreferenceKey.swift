//
//  UBPopupPreferenceKey.swift
//
//
//  Created by Matthias Felix on 14.10.22.
//

#if arch(arm64) || arch(x86_64)

    import Foundation
    import SwiftUI

    struct UBPopupPreferenceKey: PreferenceKey {
        static func reduce(value: inout UBPopupPreference?, nextValue: () -> UBPopupPreference?) {
            if let next = nextValue() {
                if value == nil || value!.date < next.date {
                    value = next
                }
            }
        }
    }

    struct UBPopupPreference: Equatable {
        let id = UUID()
        let isPresented: Binding<Bool>
        let date: Date
        let customStyle: UBPopupStyle?
        @ViewBuilder let content: () -> AnyView

        init?(isPresented: Binding<Bool>, date: Date?, customStyle: UBPopupStyle? = nil, content: @escaping () -> AnyView) {
            guard let date, isPresented.wrappedValue else { return nil }

            self.isPresented = isPresented
            self.date = date
            self.customStyle = customStyle
            self.content = content
        }

        static func == (lhs: UBPopupPreference, rhs: UBPopupPreference) -> Bool {
            lhs.id == rhs.id
                && lhs.isPresented.wrappedValue == rhs.isPresented.wrappedValue
                && lhs.date == rhs.date
                && lhs.customStyle == rhs.customStyle
        }
    }

#endif
