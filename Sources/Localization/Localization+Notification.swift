//
//  Localization+Notification.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

/// A list of notifications fired by the localization
public enum LocalizationNotification {
    /// The locale will change notification name
    public static var localeWillChange = Notification.Name("UBFoundation_LocalizationNotification_localeWillChange")

    /// The locale did change notification name
    public static var localeDidChange = Notification.Name("UBFoundation_LocalizationNotification_localeDidChange")

    /// The old identifier key in the user info dictionary
    public static var oldIdentifierKey = "oldIdentifierKey"

    /// The new identifier key in the user info dictionary
    public static var newIdentifierKey = "newIdentifierKey"
}
