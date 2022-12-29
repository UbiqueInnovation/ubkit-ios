//
//  GlobalNotificationCenter.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

/// The internal notification center for the framework
private let frameworkNotificationCenter = NotificationCenter()

extension NotificationCenter {
    /// The internal notification center for the framework
    static var frameworkDefault: NotificationCenter {
        frameworkNotificationCenter
    }
}
#endif
