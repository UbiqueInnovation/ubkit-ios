//
//  Localization+Locale.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import Foundation

extension Locale {
    /// Checks if the locale is the current locale
    public var ub_isCurrent: Bool {
        return self == .current
    }
}
