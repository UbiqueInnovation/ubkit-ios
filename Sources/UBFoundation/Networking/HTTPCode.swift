//
//  HTTPCode.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

// MARK: - HTTP code integer

extension Int {
    /// Get the http category
    public var ub_httpCodeCategory: UBHTTPCodeCategory {
        return UBHTTPCodeCategory(code: self)
    }

    /// Get the standard http code
    public var ub_standardHTTPCode: UBStandardHTTPCode? {
        return UBStandardHTTPCode(rawValue: self)
    }
}
