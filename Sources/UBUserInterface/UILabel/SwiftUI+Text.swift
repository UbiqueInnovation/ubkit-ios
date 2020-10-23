//
//  SwiftUI+Text.swift
//  
//
//  Created by Matthias Felix on 21.10.20.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public extension Text {

    func style(_ labelType: UBLabelType,
               color: Color? = nil,
               numberOfLines: Int? = nil,
               textAlignment: TextAlignment = .leading) -> some View {

        let view = self
            .font(Font(labelType.font))
            .tracking(labelType.letterSpacing ?? 0)
            .lineSpacing(labelType.font.pointSize * (labelType.lineSpacing - 1))
            .foregroundColor(color ?? Color(labelType.textColor))
            .lineLimit(numberOfLines)
            .multilineTextAlignment(textAlignment)

        return Group {
            if #available(iOS 14.0, *) {
                view
                    .textCase(labelType.isUppercased ? .uppercase : nil)
            } else {
                view
            }
        }
    }

}
