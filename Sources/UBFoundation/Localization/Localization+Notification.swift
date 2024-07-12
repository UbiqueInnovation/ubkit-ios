//
//  Localization+Notification.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

/// A list of notifications fired by the localization
public enum UBLocalizationNotification {
    /// The locale will change notification name
    public static let localeWillChange = Notification.Name("UBFoundation_LocalizationNotification_localeWillChange")

    /// The locale did change notification name
    public static let localeDidChange = Notification.Name("UBFoundation_LocalizationNotification_localeDidChange")

    /// The old locale key in the user info dictionary
    public static let oldLocaleKey = "oldLocaleKey"

    /// The new loacle key in the user info dictionary
    public static let newLocaleKey = "newLocaleKey"
}
