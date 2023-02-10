//
//  Localization+Formatter.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

public extension DateFormatter {
    /// Get a date formatter with the locale set
    ///
    /// - Parameter localization: A `UBLocalization` object
    convenience init(ub_localization localization: UBLocalization) {
        self.init()
        locale = localization.locale
    }
}

public extension DateComponentsFormatter {
    /// Get a date components formatter with the locale set
    ///
    /// - Parameter localization: A `UBLocalization` object
    convenience init(ub_localization localization: UBLocalization) {
        self.init()
        calendar = localization.locale.calendar
    }
}

public extension DateIntervalFormatter {
    /// Get a date interval formatter with the locale set
    ///
    /// - Parameter localization: A `UBLocalization` object
    convenience init(ub_localization localization: UBLocalization) {
        self.init()
        calendar = localization.locale.calendar
        locale = localization.locale
    }
}

public extension NumberFormatter {
    /// Get a number formatter with the locale set
    ///
    /// - Parameter localization: A `UBLocalization` object
    convenience init(ub_localization localization: UBLocalization) {
        self.init()
        locale = localization.locale
    }
}

public extension LengthFormatter {
    /// Get a length formatter with the locale set
    ///
    /// - Parameter localization: A `UBLocalization` object
    convenience init(ub_localization localization: UBLocalization) {
        self.init()
        numberFormatter = NumberFormatter(ub_localization: localization)
    }
}

public extension MassFormatter {
    /// Get a mass formatter with the locale set
    ///
    /// - Parameter localization: A `UBLocalization` object
    convenience init(ub_localization localization: UBLocalization) {
        self.init()
        numberFormatter = NumberFormatter(ub_localization: localization)
    }
}
