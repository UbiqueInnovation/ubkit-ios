//
//  Localization+Bundle.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation
import os.log

private let logger = Logger(subsystem: "ch.ubique.ubkit", category: "Bundle")

extension Bundle {
    /// Initialize a bundle using the locale. `Nil` if there are no bundles that matches the passed locale.
    ///
    /// This function will first try to find a bundle that matches the **language + region**.
    /// If it fails then it tries to locate a bundle using the **language** only.
    ///
    /// - Parameters:
    ///   - locale: The locale that we would like to find a bundle for.
    ///   - bundle: The bundle to use for the search. _Default: main_
    convenience init?(locale: Locale, in bundle: Bundle = .main) {
        let typeOfFile = "lproj"
        let bundlePath: String

        // We need to get the canonincal representation of the language to find the bundle path
        let localeComponents = Locale.components(fromIdentifier: locale.identifier)
        guard let languageCode = localeComponents[NSLocale.Key.languageCode.rawValue] else {
            logger.error("No language code found in locale \(locale.identifier, privacy: .public)")
            return nil
        }
        var localeComponentsWithOnlyLanguageAndRegion = [NSLocale.Key.languageCode.rawValue: languageCode]
        if let regionCode = localeComponents[NSLocale.Key.countryCode.rawValue] {
            localeComponentsWithOnlyLanguageAndRegion[NSLocale.Key.countryCode.rawValue] = regionCode
        }
        let localeIdentifierWithOnlyLanguageAndRegion = Locale.identifier(fromComponents: localeComponentsWithOnlyLanguageAndRegion)
        let bundleIdentifier = Locale.canonicalLanguageIdentifier(from: localeIdentifierWithOnlyLanguageAndRegion)

        if let bundleFromIndentifier = bundle.path(forResource: bundleIdentifier, ofType: typeOfFile) {
            // Load the bundle using the locale identifier
            bundlePath = bundleFromIndentifier
        } else if let bundleFromLanguageCode = bundle.path(forResource: languageCode, ofType: typeOfFile) {
            logger.debug("Loading bundle from language key for locale \(locale.identifier, privacy: .public).")
            // Load the bundle using only the language code
            bundlePath = bundleFromLanguageCode
        } else {
            logger.error("No bundle found in \(bundle.bundlePath, privacy: .public) for \(locale.identifier, privacy: .public)")
            // In case nothing is found return nil. We do not return the `main` bundle as it is missleading for the caller.
            // We leave the decision to fallback to the `main` bundle is up to the caller
            return nil
        }
        self.init(path: bundlePath)
    }
}
