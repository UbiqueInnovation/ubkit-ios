//
//  Logger+Error.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

/// Errors thrown by the localization
public enum UBLoggingError: Error {
    /// The bundle identifier is not found
    case bundelIdentifierNotFound
}
#endif
