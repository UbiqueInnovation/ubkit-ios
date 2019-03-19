//
//  Localization+Error.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 16.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

/// Errors thrown by the localization
public enum LocalizationError: Error {
    /// The language code is invalid.
    case invalidLanguageCode
    /// The region code is invalid.
    case invalidRegionCode
    /// The bundle is not found
    case bundelNotFound
}
