//
//  Localization+Formatter.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

extension DateFormatter {
    /// Get a date formatter with the locale set
    ///
    /// - Parameter localization: A `Localization` object
    public convenience init(localization: Localization) {
        self.init()
        locale = localization.locale
    }
}

extension DateComponentsFormatter {
    /// Get a date components formatter with the locale set
    ///
    /// - Parameter localization: A `Localization` object
    public convenience init(localization: Localization) {
        self.init()
        calendar = localization.locale.calendar
    }
}

extension DateIntervalFormatter {
    /// Get a date interval formatter with the locale set
    ///
    /// - Parameter localization: A `Localization` object
    public convenience init(localization: Localization) {
        self.init()
        calendar = localization.locale.calendar
        locale = localization.locale
    }
}

extension NumberFormatter {
    /// Get a number formatter with the locale set
    ///
    /// - Parameter localization: A `Localization` object
    public convenience init(localization: Localization) {
        self.init()
        locale = localization.locale
    }
}

extension LengthFormatter {
    /// Get a length formatter with the locale set
    ///
    /// - Parameter localization: A `Localization` object
    public convenience init(localization: Localization) {
        self.init()
        numberFormatter = NumberFormatter(localization: localization)
    }
}

extension MassFormatter {
    /// Get a mass formatter with the locale set
    ///
    /// - Parameter localization: A `Localization` object
    public convenience init(localization: Localization) {
        self.init()
        numberFormatter = NumberFormatter(localization: localization)
    }
}
