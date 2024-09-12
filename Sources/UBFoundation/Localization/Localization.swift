//
//  Localization.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

/// A class that manages localization, locale and bundles
/// The object will post notifications in the specified notification center to notify of the locale changement.
/// - SeeAlso: `LocalizationNotification` for the available notifications.
public class UBLocalization: Codable {
    /// A logger associated with localization
    static let logger: UBLogger = UBLogging.frameworkLoggerFactory(category: "Localization")

    // MARK: - Properties

    /// The locale used
    public private(set) var locale: Locale

    /// The base bundle of the locale
    public private(set) var baseBundle: Bundle?

    /// The bundle associated with the locale.
    /// - Note: This bundle may not contain a bundle identifie as it is generaly included in a parent bundle with a `info.plist`
    public private(set) var localizedBundle: Bundle?

    /// The notification center to use for posting notifications
    public var notificationCenter: NotificationCenter

    // MARK: - Initializers

    /// Initializes a localization
    ///
    /// - Parameters:
    ///   - locale: The locale to use. _Default: current_
    ///   - baseBundle: The base bundle to search in for matching localized bundles. _Default: main_
    ///   - notificationCenter: The notification center to use for all notifications generated by the localization
    public init(locale: Locale = .current, baseBundle: Bundle = .main, notificationCenter: NotificationCenter = .default) {
        self.locale = locale
        self.baseBundle = baseBundle
        localizedBundle = Bundle(locale: locale, in: baseBundle)
        self.notificationCenter = notificationCenter
    }

    /// :nodoc:
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode the locale saved
        let localeIdentifier = try container.decode(String.self, forKey: .localeIdentifier)
        locale = Locale(identifier: localeIdentifier)

        // Decode the bundle
        if let bundlePath = try container.decodeIfPresent(String.self, forKey: .bundlePath) {
            if let baseBundle = Bundle(path: bundlePath) {
                self.baseBundle = baseBundle
                localizedBundle = Bundle(locale: locale, in: baseBundle)
            }
        } else {
            UBLocalization.logger.info("Bundle path is missing")
        }

        // Set the notification center
        notificationCenter = .default
    }
}

// MARK: - Setting the locale

public extension UBLocalization {
    /// Resets the locale to the current locale
    ///
    /// - Parameter baseBundle: The bundle to use
    func resetLocaleToCurrent(baseBundle: Bundle = .main) {
        setLocale(.current, baseBundle: baseBundle)
    }

    /// Sets the language and region of the localization.
    ///
    /// - Parameters:
    ///   - languageCode: The new language to use
    ///   - regionCode: The new region to use
    ///   - baseLocale: The base locale to change. All attribute will be copied except the language and region. _Default: current_.
    ///   - baseBundle: The bundle to use
    /// - Throws: A `UBLocalizationError` if the language, region or the combination is not available.
    func setLanguage(languageCode: String, regionCode: String? = nil, baseLocale: Locale = .current, baseBundle: Bundle = .main) throws {
        var localeComponents: [String: String] = Locale.components(fromIdentifier: baseLocale.identifier)
        localeComponents[NSLocale.Key.languageCode.rawValue] = languageCode

        if let regionCode {
            localeComponents[NSLocale.Key.countryCode.rawValue] = regionCode
        } else {
            localeComponents.removeValue(forKey: NSLocale.Key.countryCode.rawValue)
        }

        let localeIdentifier = Locale.identifier(fromComponents: localeComponents)
        try setLocale(identifier: localeIdentifier, baseBundle: baseBundle)
    }

    /// Sets the locale from a locale identifier.
    ///
    /// - Parameters:
    ///   - localeIdentifier: The locale identifier
    ///   - baseBundle: The bundle to use
    /// - Throws: A `UBLocalizationError` if the identifier is not available
    func setLocale(identifier localeIdentifier: String, baseBundle: Bundle = .main) throws {
        let localeComponents = Locale.components(fromIdentifier: localeIdentifier)
        guard let languageCode = localeComponents[NSLocale.Key.languageCode.rawValue], Locale.isoLanguageCodes.contains(languageCode) else {
            UBLocalization.logger.error("The language code is not valid \(localeIdentifier)")
            throw UBLocalizationError.invalidLanguageCode
        }

        if let regionCode = localeComponents[NSLocale.Key.countryCode.rawValue], Locale.isoRegionCodes.contains(regionCode) == false {
            UBLocalization.logger.error("The region code is not valid \(localeIdentifier)")
            throw UBLocalizationError.invalidRegionCode
        }

        let newLocale = Locale(identifier: localeIdentifier)
        setLocale(newLocale, baseBundle: baseBundle)
    }

    /// Sets the locale
    ///
    /// - Parameters:
    ///   - locale: The new locale
    ///   - baseBundle: The bundle to use
    func setLocale(_ locale: Locale, baseBundle: Bundle) {
        let oldIdentifier = self.locale.identifier
        let newIdentifier = locale.identifier
        let userInfo = [UBLocalizationNotification.oldLocaleKey: self.locale, UBLocalizationNotification.newLocaleKey: locale]

        UBLocalization.logger.debug("Locale will change from [\(oldIdentifier)] to [\(newIdentifier)]")
        notificationCenter.post(name: UBLocalizationNotification.localeWillChange, object: self, userInfo: userInfo)
        self.locale = locale
        self.baseBundle = baseBundle
        localizedBundle = Bundle(locale: locale, in: baseBundle)
        UBLocalization.logger.debug("Locale did change from [\(oldIdentifier)] to [\(newIdentifier)]")
        notificationCenter.post(name: UBLocalizationNotification.localeDidChange, object: self, userInfo: userInfo)
    }
}

// MARK: - Coding complience

extension UBLocalization {
    /// :nodoc:
    enum CodingKeys: String, CodingKey {
        /// :nodoc:
        case localeIdentifier
        case bundlePath
    }

    /// :nodoc:
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locale.identifier, forKey: .localeIdentifier)
        try container.encodeIfPresent(baseBundle?.bundlePath, forKey: .bundlePath)
    }
}

// MARK: - Debug

extension UBLocalization: CustomDebugStringConvertible {
    /// :nodoc:
    public var debugDescription: String {
        "\(UBLocalization.self) (\(locale.identifier)) [\(localizedBundle?.bundlePath ?? "No bundle")]"
    }
}
