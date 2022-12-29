//
//  Localization+Notification.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

/// A list of notifications fired by the localization
public enum UBLocalizationNotification {
    /// The locale will change notification name
    public static var localeWillChange = Notification.Name("UBFoundation_LocalizationNotification_localeWillChange")

    /// The locale did change notification name
    public static var localeDidChange = Notification.Name("UBFoundation_LocalizationNotification_localeDidChange")

    /// The old locale key in the user info dictionary
    public static var oldLocaleKey = "oldLocaleKey"

    /// The new loacle key in the user info dictionary
    public static var newLocaleKey = "newLocaleKey"
}
#endif
