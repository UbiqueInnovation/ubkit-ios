//
//  KeyboardInfo.swift
//  UBFoundation iOS
//
//  Created by Joseph El Mallah on 17.05.19.
//

import UIKit

/// Translating the keyboard info into a struct
@MainActor
struct KeyboardInfo {
    // :nodoc:
    let endFrame: CGRect
    // :nodoc:
    let animationOptions: UIView.AnimationOptions
    // :nodoc:
    let animationDuration: TimeInterval

    // :nodoc:
    init?(userInfo: [AnyHashable: Any]?) {
        guard let userInfo else {
            return nil
        }
        guard let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return nil
        }

        self.endFrame = endFrame

        // https://developer.apple.com/documentation/uikit/uikeyboardanimationcurveuserinfokey
        if let animationCurveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            self.animationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw << 16)
        } else {
            animationOptions = UIView.AnimationOptions.curveLinear
        }

        if let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            self.animationDuration = animationDuration
        } else {
            animationDuration = 0.25
        }
    }

    // :nodoc:
    func animateAlongsideKeyboard(_ animations: @escaping () -> Void) {
        #if !os(visionOS)
            UIView.animate(withDuration: animationDuration, delay: 0, options: [.beginFromCurrentState, animationOptions]) {
                animations()
            }
        #else
            animations()
        #endif
    }
}
