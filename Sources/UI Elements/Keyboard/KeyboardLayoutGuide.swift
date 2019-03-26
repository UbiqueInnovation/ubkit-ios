//
//  KeyboardLayoutGuide.swift
//  UBFoundation iOS
//
//  Created by Joseph El Mallah on 26.03.19.
//

import UIKit

extension UIView {
    /// The layout guide representing the portion of your view that is obscured by the keyboard.
    ///
    /// When the view is visible onscreen, this guide reflects the portion of the view that is covered by the keyboard. If the view is not currently installed in a view hierarchy, or is not yet visible onscreen, the layout guide edges are equal to the edges of the view.
    ///
    public var keyboardLayoutGuide: UILayoutGuide {
        if let existingGuide = self.layoutGuides.first(where: { $0 is KeyboardLayoutGuide }) {
            return existingGuide
        }

        let guide = KeyboardLayoutGuide()
        guide.addToView(self)

        return guide
    }
}

/// Some code was inspiered by https://gist.github.com/u10int/bba52655942ea301ccad9f3978da6f32

/// A layout guid that follows the top of the keyboard in a view. You still need to add the layout to the view with the call `addToView`
/// - note: This class is only available for iOS
public class KeyboardLayoutGuide: UILayoutGuide {
    /// :nodoc:
    private var topConstraint: NSLayoutConstraint?

    /// Creates a following layout guide for the keyboard in the specified view
    ///
    /// - Note: Use this method to initialize an set the layout guide. If the layout guide is removed from a view it needs to be added again via the `addToView` function, Adding it manually with `addLayoutGuide` won't allow it to change sizes with the keyboard
    ///
    /// - Parameters:
    ///   - owningView: The view where the guide should belong.
    ///   - notificationCenter: The notification center to use for the keyboard notifications. The default notification will be used if not specified
    public init(notificationCenter: NotificationCenter = .default) {
        super.init()
        identifier = "Keyboard Layout Guide"

        notificationCenter.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// Adds the keyboard layout guide to a view
    ///
    /// - Parameter newOwningView: The new view
    public func addToView(_ newOwningView: UIView) {
        guard owningView != newOwningView else {
            return
        }

        let oldView = owningView
        oldView?.removeLayoutGuide(self)
        oldView?.setNeedsLayout()

        newOwningView.addLayoutGuide(self)

        topConstraint = newOwningView.bottomAnchor.constraint(equalTo: topAnchor)
        NSLayoutConstraint.activate([
            topConstraint!,
            newOwningView.leadingAnchor.constraint(equalTo: leadingAnchor),
            newOwningView.trailingAnchor.constraint(equalTo: trailingAnchor),
            newOwningView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        newOwningView.setNeedsLayout()
    }

    /// :nodoc:
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Keyboard callbacks

extension KeyboardLayoutGuide {
    // :nodoc:
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let owningView = owningView,
            let window = owningView.window,
            let keyboardInfo = KeyboardInfo(userInfo: notification.userInfo) else {
            return
        }

        // convert own frame to window coordinates, frame is in superview's coordinates
        let owningViewFrame = window.convert(owningView.frame, from: owningView.superview)
        // calculate the area of own frame that is covered by keyboard
        var coveredFrame = owningViewFrame.intersection(keyboardInfo.endFrame)
        // might be rotated, so convert it back
        coveredFrame = window.convert(coveredFrame, to: owningView.superview)

        topConstraint?.constant = coveredFrame.height
        keyboardInfo.animateAlongsideKeyboard {
            owningView.layoutIfNeeded()
        }
    }

    // :nodoc:
    @objc private func keyboardWillHide(_: Notification) {
        topConstraint?.constant = 0.0
    }
}

/// Translating the keyboard info into a struct
private struct KeyboardInfo {
    // :nodoc:
    let endFrame: CGRect
    // :nodoc:
    let animationCurve: UIView.AnimationCurve
    // :nodoc:
    let animationDuration: TimeInterval

    // :nodoc:
    init?(userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo else {
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
    func animateAlongsideKeyboard(_ animations: () -> Void) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDelay(0)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        UIView.setAnimationBeginsFromCurrentState(true)
        animations()
        UIView.commitAnimations()
    }
}
