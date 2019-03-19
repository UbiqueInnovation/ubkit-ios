//
//  OSLog+Categories.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 17.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    /// Initializes the logger with a category using the bundle as a subsystem
    ///
    /// - Parameters:
    ///   - category: The category to log. _Example: use Networking as a category for all networking activity logging_
    ///   - bundle: The bundle to use
    public convenience init(category: String, bundle: Bundle = .main) {
        guard let bundleIdentifier = bundle.bundleIdentifier else {
            fatalError("There is no bundle identifier")
        }
        self.init(subsystem: bundleIdentifier, category: category)
    }
}
