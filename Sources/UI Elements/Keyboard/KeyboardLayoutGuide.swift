//
//  KeyboardLayoutGuide.swift
//  UBFoundation iOS
//
//  Created by Joseph El Mallah on 26.03.19.
//

import UIKit

/// Some code was inspiered by https://gist.github.com/u10int/bba52655942ea301ccad9f3978da6f32

/// A layout guid that follows the top of the keyboard in a view.
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
    public init(addToView owningView: UIView? = nil, notificationCenter: NotificationCenter = .default) {
        super.init()
        identifier = "Keyboard Layout Guide"

        if let owningView = owningView {
            addToView(owningView)
        }

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
        guard let owningView = owningView else { return }
        guard let window = owningView.window else { return }
        guard let keyboardInfo = KeyboardInfo(userInfo: notification.userInfo) else { return }

        // convert own frame to window coordinates, frame is in superview's coordinates
        let owningViewFrame = window.convert(owningView.frame, from: owningView.superview)
        // calculate the area of own frame that is covered by keyboard
        var coveredFrame = owningViewFrame.intersection(keyboardInfo.endFrame)
        // might be rotated, so convert it back
        coveredFrame = window.convert(coveredFrame, to: owningView.superview)

        keyboardInfo.animateAlongsideKeyboard {
            self.topConstraint?.constant = coveredFrame.height
            owningView.layoutIfNeeded()
        }
    }

    // :nodoc:
    @objc private func keyboardWillHide(_: Notification) {
        topConstraint?.constant = 0.0
        owningView?.setNeedsLayout()
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
