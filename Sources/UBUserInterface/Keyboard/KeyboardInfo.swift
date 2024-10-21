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
    let animationCurve: UIView.AnimationCurve
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

        // UIViewAnimationOption is shifted by 16 bit from UIViewAnimationCurve, which we get here:
        // http://stackoverflow.com/questions/18870447/how-to-use-the-default-ios7-uianimation-curve
        if let animationCurveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int, let animationCurve = UIView.AnimationCurve(rawValue: animationCurveRaw) {
            self.animationCurve = animationCurve
        } else {
            animationCurve = .linear
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
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.beginFromCurrentState, getAnimationOption(from: animationCurve)]) {
            animations()
        }
#else
        animations()
#endif
    }

    private func getAnimationOption(from curve: UIView.AnimationCurve) -> UIView.AnimationOptions {
        switch curve {
            case .easeInOut: .curveEaseInOut
            case .easeIn: .curveEaseIn
            case .easeOut: .curveEaseOut
            case .linear: .curveLinear
            @unknown default: fatalError()
        }
    }
}
