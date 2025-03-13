//
//  UIAccessibility+Helper.swift
//  UBFoundation
//
//  Created by Jan Huber on 06.05.2024.
//

@preconcurrency import UIKit

public extension UIAccessibility {
    /// Reads an announcement to VoiceOver users that cannot be interrupted by other announcements on devices running iOS 17 or never.
    /// - Parameter message: the message to read
    @MainActor static func ub_postHighPriorityAnnouncement(_ message: String) {
        if #available(iOS 17, watchOS 10.0, *) {
            let announcement = NSAttributedString(
                string: message,
                attributes: [NSAttributedString.Key.accessibilitySpeechAnnouncementPriority: UIAccessibilityPriority.high]
            )
            AccessibilityNotification.Announcement(announcement).post()
        } else {
            #if os(iOS)
                UIAccessibility.post(notification: .announcement, argument: message)
            #endif
        }
    }
}
