//
//  ViewKeyboardLayoutGuide.swift
//  UBFoundation iOS
//
//  Created by Joseph El Mallah on 17.05.19.
//

import UIKit

/// A layout guid that follows the top of the keyboard in a view.
/// - Note: This class is only available for iOS
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

    /// :nodoc:
    override var owningView: UIView? {
        willSet {
            guard owningView != newValue else {
                return
            }

            // If the new view is different than the old one, remove the window reference
            establishedToWindow = nil
        }
        didSet {
            guard owningView != oldValue, let owningView = owningView else {
                return
            }

            // Setup the constraint for when there is no keyboard showing
            let noKeyboardConstraint = topAnchor.constraint(equalTo: owningView.bottomAnchor)
            self.noKeyboardConstraint = noKeyboardConstraint

            // Check if the view is already in a window
            if let window = owningView.window {
                // Get the keyboard layout guide
                guard let windowKeyboardLayoutGuide = window.windowKeyboardLayoutGuide else {
                    // The window was not initialized properly
                    fatalError("The current window \(window) is not initialized for keyboard monitoring. Please call initializeForKeyboardLayoutGuide() after the window is initialized. Typically shortly after the app launches and the window is available.")
                }
                // Setup the keyboard constraint top matches the keyboard guide
                let keyboardConstraint: NSLayoutConstraint
                keyboardConstraint = windowKeyboardLayoutGuide.topAnchor.constraint(equalTo: topAnchor)
                keyboardConstraint.priority = UILayoutPriority(999)
                keyboardConstraint.isActive = true
                self.keyboardConstraint = keyboardConstraint
                // Save a reference to the window for verification later if it changes
                establishedToWindow = window
            } else {
                // Activate the no keyboard constaint in case the view is not yet part of a window hierarchy
                noKeyboardConstraint.isActive = true
            }

            // Setup the constraint
            NSLayoutConstraint.activate([
                topAnchor.constraint(lessThanOrEqualTo: owningView.bottomAnchor), // The top should never be outside of the view
                topAnchor.constraint(greaterThanOrEqualTo: owningView.topAnchor), // The top should never be outside of the view
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
            // Animate alongside the keyboard
            owningView.setNeedsLayout()
            keyboardInfo.animateAlongsideKeyboard {
                owningView.layoutIfNeeded()
            }
        }

        if let establishedToWindow = establishedToWindow, establishedToWindow == owningView.window, keyboardConstraint != nil {
            // If everything is still the same then just make sure we are using the keyboard constraint
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
            // If we got a window, setup the needed constraints to pin the top of the guide to the top of the keyboard
            let keyboardConstraint: NSLayoutConstraint
            keyboardConstraint = windowKeyboardLayoutGuide.topAnchor.constraint(equalTo: topAnchor)
            keyboardConstraint.priority = UILayoutPriority(999)
            keyboardConstraint.isActive = true
            self.keyboardConstraint = keyboardConstraint
            establishedToWindow = window
            noKeyboardConstraint?.isActive = false
        } else {
            // If we do no longer have a window, return back to pinning to the bottom of the owning view
            establishedToWindow = nil
            noKeyboardConstraint?.isActive = true
        }
    }

    // :nodoc:
    @objc private func keyboardWillHide(_: Notification) {
        // Pin to the bottom of the owning view
        noKeyboardConstraint?.isActive = true
        owningView?.setNeedsLayout()
    }
}
