//
//  Networking+Logger.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 25.03.19.
//

import Foundation

/// A name space for networking
public enum Networking {
    /// A logger associated with data tasks
    internal static let logger: Logger = Logging.frameworkLoggerFactory(category: "Networking")
}
