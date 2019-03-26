//
//  KeyboardLayoutGuide.swift
//  UBFoundation iOS
//
//  Created by Joseph El Mallah on 26.03.19.
//

import UIKit

/// This code is highly inspiered by https://gist.github.com/u10int/bba52655942ea301ccad9f3978da6f32

/// A layout guid that follows the top of the keyboard in a view.
/// - note: This class is only available for iOS
final class KeyboardLayoutGuide {
    /// :nodoc:
    private let bottomConstraint: NSLayoutConstraint

    /// The layout guide that follows the keyboard
    public let topGuide: UILayoutGuide

    /// Creates a following layout guide for the keyboard in the specified view
    ///
    /// - Parameters:
    ///   - parentView: The parent view where the guide should belong.
    ///   - notificationCenter: The notification center to use for the keyboard notifications. The default notification will be used if not specified
    public init(parentView: UIView, notificationCenter: NotificationCenter = .default) {
        topGuide = UILayoutGuide()
        topGuide.identifier = "Keyboard Layout Guide"
        parentView.addLayoutGuide(topGuide)

        bottomConstraint = parentView.bottomAnchor.constraint(equalTo: topGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            self.topGuide.heightAnchor.constraint(equalToConstant: 0.0),
            parentView.leadingAnchor.constraint(equalTo: self.topGuide.leadingAnchor),
            parentView.trailingAnchor.constraint(equalTo: self.topGuide.trailingAnchor),
            self.bottomConstraint
        ])

        notificationCenter.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: - Keyboard callbacks

extension KeyboardLayoutGuide {
    // :nodoc:
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let owningView = self.topGuide.owningView else { return }
        guard let window = owningView.window else { return }
        guard let keyboardInfo = KeyboardInfo(userInfo: notification.userInfo) else { return }

        // convert own frame to window coordinates, frame is in superview's coordinates
        let owningViewFrame = window.convert(owningView.frame, from: owningView.superview)
        // calculate the area of own frame that is covered by keyboard
        var coveredFrame = owningViewFrame.intersection(keyboardInfo.endFrame)
        // might be rotated, so convert it back
        coveredFrame = window.convert(coveredFrame, to: owningView.superview)

        keyboardInfo.animateAlongsideKeyboard {
            self.bottomConstraint.constant = coveredFrame.height
            owningView.layoutIfNeeded()
        }
    }

    // :nodoc:
    @objc private func keyboardWillHide(_: Notification) {
        bottomConstraint.constant = 0.0
        topGuide.owningView?.layoutIfNeeded()
    }
}

/// Translating the keyboard info into a struct
private struct KeyboardInfo {
    // :nodoc:
    let endFrame: CGRect
    // :nodoc:
    let animationOptions: UIView.AnimationOptions
    // :nodoc:
    let animationDuration: TimeInterval

    // :nodoc:
    init?(userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo else { return nil }
        guard let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return nil }

        self.endFrame = endFrame

        // UIViewAnimationOption is shifted by 16 bit from UIViewAnimationCurve, which we get here:
        // http://stackoverflow.com/questions/18870447/how-to-use-the-default-ios7-uianimation-curve
        if let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            self.animationOptions = UIView.AnimationOptions(rawValue: animationCurve << 16)
        } else {
            self.animationOptions = .curveEaseInOut
        }

        if let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            self.animationDuration = animationDuration
        } else {
            self.animationDuration = 0.25
        }
    }

    // :nodoc:
    func animateAlongsideKeyboard(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: self.animationDuration, delay: 0.0, options: self.animationOptions, animations: animations)
    }
}
