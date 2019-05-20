//
//  Language.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 17.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

// MARK: - Language

extension Localization {
    /// Holds information about a language
    public struct Language: Codable, Hashable, CustomStringConvertible {
        // MARK: - Properties

        /// The identifier of the language
        public let identifier: String

        // MARK: - Initializers

        /// Initializes a language
        ///
        /// The identifier can be composed of a language or with a language combined with a region. *Example: `en_CH`*
        ///
        /// - Parameter identifier: The identifier of the language
        public init(identifier: String) {
            self.identifier = identifier
        }

        // MARK: Display Names

        /// Generates a display name using the passed `Localization`
        ///
        /// - Parameter localization: A `Localization` to use
        /// - Returns: The name of the language using the passed `Localization`
        public func displayName(_ localization: Localization) -> String? {
            return localization.locale.localizedString(forIdentifier: identifier)
        }

        /// Returns the display name of the language in it's native form
        public var displayNameInNativeLanguage: String? {
            let originalLocale = Locale(identifier: identifier)
            return originalLocale.localizedString(forIdentifier: identifier)
        }

        /// :nodoc:
        public var description: String {
            return displayNameInNativeLanguage ?? identifier
        }
    }
}
