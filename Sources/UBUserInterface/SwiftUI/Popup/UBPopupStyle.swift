//
//  UBPopupStyle.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

    import SwiftUI

    @available(iOS 14.0, *)
    public struct UBPopupStyle {
        let extendsToEdges: Bool
        let backgroundColor: Color
        let cornerRadius: CGFloat
        let insets: EdgeInsets
        let horizontalPadding: CGFloat
        let tapOutsideToDismiss: Bool

        public init(extendsToEdges: Bool = true,
                    backgroundColor: Color = .white,
                    cornerRadius: CGFloat = 15,
                    insets: EdgeInsets = .zero,
                    horizontalPadding: CGFloat = 20,
                    tapOutsideToDismiss: Bool = true) {
            self.extendsToEdges = extendsToEdges
            self.backgroundColor = backgroundColor
            self.cornerRadius = cornerRadius
            self.insets = insets
            self.horizontalPadding = horizontalPadding
            self.tapOutsideToDismiss = tapOutsideToDismiss
        }
    }

#endif
