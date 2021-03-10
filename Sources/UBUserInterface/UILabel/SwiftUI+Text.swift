//
//  SwiftUI+Text.swift
//  
//
//  Created by Matthias Felix on 21.10.20.
//

#if (arch(arm64) || arch(x86_64))

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public extension Text {

    /**
     Styles a SwiftUI `Text` view with the values specified in a given `UBLabelType`, with the option to override specific style attributes.

     - Parameter labelType: The label type whose parameters should be applied to the text.
     - Parameter color: If not `nil`, this color takes precedence over the label type's `textColor`.
     - Parameter numberOfLines: The maximum numer of lines the label is allowed to have. Specify `nil` to allow for an infinite number of lines.
     - Parameter textAlignment: The text alignment that should be used for the label. Default is `leading`.
     */
    func ub_style(_ labelType: UBLabelType,
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

#endif
