//
//  HTTPCode.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

// MARK: - HTTP code integer

public extension Int {
    /// Get the http category
    var ub_httpCodeCategory: UBHTTPCodeCategory {
        UBHTTPCodeCategory(code: self)
    }

    /// Get the standard http code
    var ub_standardHTTPCode: UBStandardHTTPCode? {
        UBStandardHTTPCode(rawValue: self)
    }
}
#endif
