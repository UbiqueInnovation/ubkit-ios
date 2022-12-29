//
//  Localization+Languages.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

// MARK: - Getting languages

public extension UBLocalization {
    /// Returns the preferred languages list modified to match the locale set.
    ///
    /// In the default case, the list is made up of the languages that the user sorted in the system settings and also are available in the app.
    /// The set locale will be pushed to the top if found, otherwise it will be added.
    ///
    /// - Note: This function does not validate the _preferredLanguages_ with the available localization of the app.
    ///
    /// - Parameters:
    ///   - stripRegionInformation: If the list should not contain any region information. _Default: true_
    ///   - preferredLanguages: The list of prefered languages to check against. _Default: Bundle.main.preferredLocalizations_
    /// - Returns: The list of preferred languages
    func preferredLanguages(stripRegionInformation: Bool = true, preferredLanguages: [String]? = nil) -> [Language] {
        let bundle = baseBundle ?? .main
        // load the list of preferred languages as the user defined them in the OS
        var mutablePreferredLanguages: [String] = preferredLanguages ?? bundle.preferredLocalizations

        // This will hold the set language identifier according to the localization
        let currentLanguageIdentifier: String

        // Strip the region information if necessary
        if stripRegionInformation {
            // Remove all the region information of the OS preferred languages. Take everything before the "-"
            mutablePreferredLanguages = mutablePreferredLanguages.map {
                let localeComponents = Locale.components(fromIdentifier: $0)
                return localeComponents[NSLocale.Key.languageCode.rawValue] ?? $0
            }
            // Since we won't have any region information, we should only use the locale language code if possible.
            // Fallback to the locale identifier if no language is found
            currentLanguageIdentifier = locale.languageCode ?? locale.identifier
        } else {
            // If we keep the region info then we use the locale identifier
            currentLanguageIdentifier = locale.identifier
        }

        // We remove the move the current language to the top of the list
        mutablePreferredLanguages.removeAll(where: { $0 == currentLanguageIdentifier })
        mutablePreferredLanguages.insert(currentLanguageIdentifier, at: 0)

        return mutablePreferredLanguages.map { Language(identifier: $0) }
    }

    /// Returns all the available localizations of the app.
    ///
    /// - Parameters:
    ///   - stripRegionInformation: If the list should not contain any region information. *Default: true*
    ///   - bundle: The bundle to search in
    /// - Returns: A list of available localizations in the app.
    static func availableLanguages(stripRegionInformation: Bool = true, bundle: Bundle = .main) -> Set<Language> {
        var localizations = bundle.localizations
        if stripRegionInformation {
            localizations = localizations.map {
                let localeComponents = Locale.components(fromIdentifier: $0)
                return localeComponents[NSLocale.Key.languageCode.rawValue] ?? $0
            }
        }
        let languages = localizations.map { Language(identifier: $0) }
        return Set(languages)
    }
}
#endif
