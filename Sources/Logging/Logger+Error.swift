//
//  Logger+Error.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//  Copyright © 2019 Ubique. All rights reserved.

import Foundation

/// Errors thrown by the localization
public enum LoggingError: Error {
    /// The bundle identifier is not found
    case bundelIdentifierNotFound
}
