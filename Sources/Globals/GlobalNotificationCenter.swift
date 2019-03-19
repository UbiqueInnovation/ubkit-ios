//
//  GlobalNotificationCenter.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import Foundation

/// The internal notification center for the framework
private let frameworkNotificationCenter = NotificationCenter()

extension NotificationCenter {
    /// The internal notification center for the framework
    internal static var frameworkDefault: NotificationCenter {
        return frameworkNotificationCenter
    }
}
