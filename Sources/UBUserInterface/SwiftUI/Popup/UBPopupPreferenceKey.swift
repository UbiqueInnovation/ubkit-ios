//
//  UBPopupPreferenceKey.swift
//
//
//  Created by Matthias Felix on 14.10.22.
//

#if arch(arm64) || arch(x86_64)

    import Foundation
    import SwiftUI

    @available(iOS 13.0, *)
    public struct UBPopupPreferenceKey: PreferenceKey {
        public static func reduce(value: inout UBPopupPreference?, nextValue: () -> UBPopupPreference?) {
            if let next = nextValue() {
                if value == nil || value!.date < next.date {
                    value = next
                }
            }
        }
    }

    @available(iOS 13.0, *)
    public struct UBPopupPreference: Equatable {
        public let id = UUID()
        public let isPresented: Binding<Bool>
        public let date: Date
        public let customStyle: UBPopupStyle?
        @ViewBuilder public let content: () -> AnyView

        public init?(isPresented: Binding<Bool>, date: Date?, customStyle: UBPopupStyle? = nil, content: @escaping () -> AnyView) {
            guard let date, isPresented.wrappedValue else { return nil }

            self.isPresented = isPresented
            self.date = date
            self.customStyle = customStyle
            self.content = content
        }

        public static func == (lhs: UBPopupPreference, rhs: UBPopupPreference) -> Bool {
            print("Comparing lhs & rhs:", lhs, rhs)
            return lhs.id == rhs.id && lhs.isPresented.wrappedValue == rhs.isPresented.wrappedValue && lhs.date == rhs.date && lhs.customStyle == rhs.customStyle
        }
    }

#endif
