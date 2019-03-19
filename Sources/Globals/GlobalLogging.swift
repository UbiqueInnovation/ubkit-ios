//
//  GlobalLogging.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 17.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation
import os.log

/// Internal logger group that holds all loggers
internal var loggerGroup: LoggerGroup = LoggerGroup()

/// A domain for framework logging manipulation
public enum Logging {
    /// Sets the global log level for all framework loggers
    ///
    /// - Parameter newLogLevel: The new log level
    public static func setGlobalLogLevel(_ newLogLevel: Logger.LogLevel) {
        loggerGroup.set(groupLogLevel: newLogLevel)
    }

    /// Add a logger to the global logger groups
    ///
    /// - Parameter logger: The logger to add
    internal static func addLogger(_ logger: Logger) {
        loggerGroup.add(logger: logger)
    }

    /// Returns a logger factory for logging framework activity.
    ///
    /// The logger produced by this method are not suited for the App use.
    /// They use the Framework bundle and may result in confuson if passed to the outside.
    ///
    /// - Parameter category: The category of the logger
    /// - Returns: A logger for the framework use
    internal static func frameworkLoggerFactory(category: String) -> Logger {
        let osLog = OSLog(category: category, bundle: Bundle(for: Logger.self))
        let logger = Logger(osLog)
        addLogger(logger)
        return logger
    }
}
