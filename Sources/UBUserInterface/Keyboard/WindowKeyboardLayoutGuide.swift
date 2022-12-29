//
//  WindowKeyboardLayoutGuide.swift
//  UBFoundation iOS
//
//  Created by Joseph El Mallah on 26.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

/// Some code was inspiered by https://gist.github.com/u10int/bba52655942ea301ccad9f3978da6f32

/// A layout guid that follows the top of the keyboard in a window.
/// - Note: This class is only available for iOS
class WindowKeyboardLayoutGuide: UILayoutGuide {
    /// :nodoc:
    private weak var topConstraint: NSLayoutConstraint?

    /// Creates a following layout guide for the keyboard in the specified window
    ///
    /// - Parameters:
    ///   - notificationCenter: The notification center to use for the keyboard notifications. The default notification will be used if not specified
    init(notificationCenter: NotificationCenter = .default) {
        super.init()
        identifier = "Window Keyboard Layout Guide"

        notificationCenter.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// :nodoc:
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // :nodoc:
    override var owningView: UIView? {
        didSet {
            guard owningView != oldValue, let owningView = owningView else {
                return
            }

            // Establish the constaints and one in particular that will be used when the keyboard shows
            let topConstraint = owningView.bottomAnchor.constraint(equalTo: topAnchor)
            self.topConstraint = topConstraint
            NSLayoutConstraint.activate([
                topConstraint,
                owningView.leadingAnchor.constraint(equalTo: leadingAnchor),
                owningView.trailingAnchor.constraint(equalTo: trailingAnchor),
                owningView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            owningView.setNeedsLayout()
        }
    }
}

// MARK: - Keyboard callbacks

extension WindowKeyboardLayoutGuide {
    // :nodoc:
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let owningView = owningView,
              let window = owningView as? UIWindow,
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
        owningView?.setNeedsLayout()
    }
}
#endif
