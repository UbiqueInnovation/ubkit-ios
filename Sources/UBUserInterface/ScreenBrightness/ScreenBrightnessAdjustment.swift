//
//  ScreenBrightnessAdjustment.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 11.02.22.
//

import Foundation
import UIKit

/// Handles the brightness of the screen when a different targetBrightness is needed. This brightness is also restored when the app resigns active and becomes active again. Also keeps the screen at the target brightness by disabling the idle timer.
open class ScreenBrightnessAdjustment {
    private var screenBrightness: ScreenBrightness?
    private let targetBrightness: CGFloat

    public init(targetBrightness: CGFloat) {
        self.targetBrightness = targetBrightness
    }

    public func adjust() {
        self.isEnabled = true
    }

    public func reset() {
        self.isEnabled = false
    }

    /// Enables adjustment of the screen
    private var isEnabled: Bool = false {
        didSet {
            updateApplicationIdleTimer()
            updateScreenBrightness()
        }
    }

    private func updateApplicationIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = isEnabled
    }

    private func updateScreenBrightness() {
        if isEnabled {
            if screenBrightness == nil {
                screenBrightness = ScreenBrightness(targetBrightness: self.targetBrightness)
            }
        } else {
            screenBrightness = nil
        }
    }
}
