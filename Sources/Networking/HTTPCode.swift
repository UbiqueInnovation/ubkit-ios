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
    public var httpCodeCategory: HTTPCodeCategory {
        return HTTPCodeCategory(code: self)
    }

    /// Get the standard http code
    public var standardHTTPCode: StandardHTTPCode? {
        return StandardHTTPCode(rawValue: self)
    }
}
