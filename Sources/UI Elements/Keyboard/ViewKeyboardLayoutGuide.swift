//
//  ViewKeyboardLayoutGuide.swift
//  UBFoundation iOS
//
//  Created by Joseph El Mallah on 17.05.19.
//

import UIKit

/// A layout guid that follows the top of the keyboard in a view.
/// - note: This class is only available for iOS
class ViewKeyboardLayoutGuide: UILayoutGuide {
    /// :nodoc:
    private weak var noKeyboardConstraint: NSLayoutConstraint?

    /// :nodoc:
    private weak var keyboardConstraint: NSLayoutConstraint?
    /// :nodoc:
    private weak var establishedToWindow: UIWindow?

    /// Creates a following layout guide for the keyboard in the specified window
    ///
    /// - Parameters:
    ///   - notificationCenter: The notification center to use for the keyboard notifications. The default notification will be used if not specified
    init(notificationCenter: NotificationCenter = .default) {
        super.init()
        identifier = "View Keyboard Layout Guide"

        notificationCenter.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// :nodoc:
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var owningView: UIView? {
        willSet {
            guard owningView != newValue else {
                return
            }

            establishedToWindow = nil

            if let keyboardConstraint = keyboardConstraint {
                owningView?.removeConstraint(keyboardConstraint)
            }
            if let noKeyboardConstraint = noKeyboardConstraint {
                owningView?.removeConstraint(noKeyboardConstraint)
            }
        }
        didSet {
            guard owningView != oldValue, let owningView = owningView else {
                return
            }

            let noKeyboardConstraint = topAnchor.constraint(equalTo: owningView.bottomAnchor)
            self.noKeyboardConstraint = noKeyboardConstraint

            if let window = owningView.window {
                guard let windowKeyboardLayoutGuide = window.windowKeyboardLayoutGuide else {
                    fatalError("The current window \(window) is not initialized for keyboard monitoring. Please call initializeForKeyboardLayoutGuide() after the window is initialized. Typically shortly after the app launches and the window is available.")
                }
                let keyboardConstraint: NSLayoutConstraint
                keyboardConstraint = windowKeyboardLayoutGuide.topAnchor.constraint(equalTo: topAnchor)
                keyboardConstraint.priority = UILayoutPriority(999)
                keyboardConstraint.isActive = true
                self.keyboardConstraint = keyboardConstraint
                establishedToWindow = window
            } else {
                noKeyboardConstraint.isActive = true
            }

            NSLayoutConstraint.activate([
                topAnchor.constraint(lessThanOrEqualTo: owningView.bottomAnchor),
                owningView.leadingAnchor.constraint(equalTo: leadingAnchor),
                owningView.trailingAnchor.constraint(equalTo: trailingAnchor),
                owningView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            owningView.setNeedsLayout()
        }
    }
}

// MARK: - Keyboard callbacks

extension ViewKeyboardLayoutGuide {
    // :nodoc:
    @objc private func keyboardWillChangeFrame(notification: Notification) {
        guard let owningView = owningView, let keyboardInfo = KeyboardInfo(userInfo: notification.userInfo) else {
            return
        }

        defer {
            owningView.setNeedsLayout()
            keyboardInfo.animateAlongsideKeyboard {
                owningView.layoutIfNeeded()
            }
        }

        if let establishedToWindow = establishedToWindow, establishedToWindow == owningView.window, keyboardConstraint != nil {
            noKeyboardConstraint?.isActive = false
            return
        }

        if let keyboardConstraint = keyboardConstraint {
            owningView.removeConstraint(keyboardConstraint)
        }

        if let window = owningView.window {
            guard let windowKeyboardLayoutGuide = window.windowKeyboardLayoutGuide else {
                fatalError("The current window \(window) is not initialized for keyboard monitoring. Please call initializeForKeyboardLayoutGuide() after the window is initialized. Typically shortly after the app launches and the window is available.")
            }

            let keyboardConstraint: NSLayoutConstraint
            keyboardConstraint = windowKeyboardLayoutGuide.topAnchor.constraint(equalTo: topAnchor)
            keyboardConstraint.priority = UILayoutPriority(999)
            keyboardConstraint.isActive = true
            self.keyboardConstraint = keyboardConstraint
            establishedToWindow = window
            noKeyboardConstraint?.isActive = false
        } else {
            establishedToWindow = nil
            noKeyboardConstraint?.isActive = true
        }
    }

    // :nodoc:
    @objc private func keyboardWillHide(_: Notification) {
        noKeyboardConstraint?.isActive = true
    }
}
