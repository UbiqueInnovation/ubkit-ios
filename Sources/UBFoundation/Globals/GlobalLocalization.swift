//
//  GlobalLocalization.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import Foundation

/// Sets the language of the framework and the associated localization object
///
/// - Parameters:
///   - languageCode: The new language code. _Example: en_
///   - regionCode: The new region code. _Example: CH_
/// - Throws: A `UBLocalizationError` if the language, region or the combination is not available.
public func setLanguage(languageCode: String, regionCode: String? = nil) throws {
    try globalLocalization.appLocalization.setLanguage(languageCode: languageCode, regionCode: regionCode, baseLocale: .current, baseBundle: .main)
}

/// The localization object to be used by the app
public var UBAppLocalization: UBLocalization {
    globalLocalization.appLocalization
}

/// The localization to be used within the framework
internal var frameworkLocalization: UBLocalization {
    globalLocalization.frameworkLocalization
}

/// A shared global object for localization
private let globalLocalization: GlobalLocalization = {
    let al = UBLocalization(locale: .current, baseBundle: .main, notificationCenter: .default)
    let fl = UBLocalization(locale: al.locale, baseBundle: Bundle(for: GlobalLocalization.self), notificationCenter: NotificationCenter.frameworkDefault)
    let shared = GlobalLocalization(appLocalization: al, frameworkLocalization: fl)
    return shared
}()

/// Global localization object
private class GlobalLocalization {
    /// The localization of the framework
    let frameworkLocalization: UBLocalization
    /// The localization of the app
    let appLocalization: UBLocalization

    /// :nodoc:
    fileprivate init(appLocalization: UBLocalization, frameworkLocalization: UBLocalization) {
        self.appLocalization = appLocalization
        self.frameworkLocalization = frameworkLocalization
        appLocalization.notificationCenter.addObserver(self, selector: #selector(appLanguageWillChange(notification:)), name: UBLocalizationNotification.localeWillChange, object: appLocalization)
    }

    @objc
    /// :nodoc:
    private func appLanguageWillChange(notification: Notification) {
        guard let newLocale = notification.userInfo?[UBLocalizationNotification.newLocaleKey] as? Locale else {
            UBLocalization.logger.error("Received language change notification without the new locale as info", accessLevel: .public)
            return
        }
        frameworkLocalization.setLocale(newLocale, baseBundle: Bundle(for: GlobalLocalization.self))
    }
}
