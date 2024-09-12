//
//  Logger+Error.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//  Copyright © 2019 Ubique. All rights reserved.

import Foundation

/// Errors thrown by the localization
@available(*, message: "Use #print or OS.Logger instead")
public enum UBLoggingError: Error {
    /// The bundle identifier is not found
    case bundelIdentifierNotFound
}
