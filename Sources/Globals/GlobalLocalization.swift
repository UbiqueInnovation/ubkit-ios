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
/// - Throws: A `LocalizationError` if the language, region or the combination is not available.
public func setLanguage(languageCode: String, regionCode: String? = nil) throws {
    try globalLocalization.appLocalization.setLanguage(languageCode: languageCode, regionCode: regionCode, baseLocale: .current, baseBundle: .main)
}

/// The localization object to be used by the app
public var appLocalization: Localization {
    return globalLocalization.appLocalization
}

/// The localization to be used within the framework
internal var frameworkLocalization: Localization {
    return globalLocalization.frameworkLocalization
}

/// A shared global object for localization
private let globalLocalization: GlobalLocalization = {
    let al = Localization(locale: .current, baseBundle: .main, notificationCenter: .default)
    let fl = Localization(locale: al.locale, baseBundle: Bundle(for: GlobalLocalization.self), notificationCenter: NotificationCenter.frameworkDefault)
    let shared = GlobalLocalization(appLocalization: al, frameworkLocalization: fl)
    return shared
}()

/// Global localization object
private class GlobalLocalization {
    /// The localization of the framework
    let frameworkLocalization: Localization
    /// The localization of the app
    let appLocalization: Localization

    /// :nodoc:
    fileprivate init(appLocalization: Localization, frameworkLocalization: Localization) {
        self.appLocalization = appLocalization
        self.frameworkLocalization = frameworkLocalization
        appLocalization.notificationCenter.addObserver(self, selector: #selector(appLanguageWillChange(notification:)), name: LocalizationNotification.localeWillChange, object: appLocalization)
    }

    @objc
    /// :nodoc:
    private func appLanguageWillChange(notification: Notification) {
        guard let newLocale = notification.userInfo?[LocalizationNotification.newLocaleKey] as? Locale else {
            Localization.logger.error("Received language change notification without the new locale as info", accessLevel: .public)
            return
        }
        frameworkLocalization.setLocale(newLocale, baseBundle: Bundle(for: GlobalLocalization.self))
    }
}
