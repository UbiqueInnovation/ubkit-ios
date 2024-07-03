//
//  Localization+String.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

public extension String {
    /// Returns a localized version of the string using the AppLocalization object.
    ///
    /// If no localization is found the string is returned.
    var ub_localized: String {
        NSLocalizedString(self, tableName: nil, bundle: .main, value: self, comment: "")
    }
}
