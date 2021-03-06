//
//  Localization+Locale.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import Foundation

public extension Locale {
    /// Checks if the locale is the current locale
    var ub_isCurrent: Bool {
        self == .current
    }
}
