//
//  UBPopupStyle.swift
//
//
//  Created by Matthias Felix on 27.09.22.
//

#if arch(arm64) || arch(x86_64)

import SwiftUI

public struct UBPopupStyle: Equatable {
    let extendsToEdges: Bool
    let backgroundColor: Color
    let backdropColor: Color
    let cornerRadius: CGFloat
    let insets: EdgeInsets
    let horizontalPadding: CGFloat
    let tapOutsideToDismiss: Bool

    public init(extendsToEdges: Bool = true,
                backgroundColor: Color = .white,
                backdropColor: Color = Color.black.opacity(0.8),
                cornerRadius: CGFloat = 15,
                insets: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                horizontalPadding: CGFloat = 20,
                tapOutsideToDismiss: Bool = true) {
        self.extendsToEdges = extendsToEdges
        self.backgroundColor = backgroundColor
        self.backdropColor = backdropColor
        self.cornerRadius = cornerRadius
        self.insets = insets
        self.horizontalPadding = horizontalPadding
        self.tapOutsideToDismiss = tapOutsideToDismiss
    }
}

#endif
