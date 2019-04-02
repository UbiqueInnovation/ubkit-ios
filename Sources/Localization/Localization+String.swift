//
//  Localization+String.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

extension String {
    /// Returns a localized version of the string using the passed localization.
    ///
    /// This method will use the bundle of the passed localization object to resolve the string.
    ///
    /// - SeeAlso: `Localization`
    ///
    /// - Parameter localization: The localization to use
    /// - Returns: The localized string
    /// - Throws: `LocalizationError` if there is no bundle in the localization
    public func localized(localization: Localization) throws -> String {
        let comment: String = ""
        guard let bundle = localization.localizedBundle else {
            Localization.logger.error("Bundle not found for \(localization.debugDescription)")
            throw LocalizationError.bundelNotFound
        }
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: self, comment: comment)
    }

    /// Returns a localized version of the string using the AppLocalization object.
    ///
    /// If no localization is found the string is returned.
    ///
    /// - Note:Use it only for apps as it uses the main bundle to get localizations. In case of a framework please refer to the function `func localized(localization:)` and pass in your framework localization.
    public var localized: String {
        do {
            return try localized(localization: AppLocalization)
        } catch {
            return self
        }
    }

    /// Localizes a string using the framework localization
    internal var frameworkLocalized: String {
        do {
            return try localized(localization: frameworkLocalization)
        } catch {
            return self
        }
    }
}
