//
//  LoggerGroup.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 17.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation

/// A group of loggers. The LoggerGroup is thread safe
public class LoggerGroup {
    /// The backing data of the group
    private var _loggers: [Logger]

    /// The group log level
    private var groupLogLevel: Logger.LogLevel?

    /// Thread safety
    private let loggersDispatchQueue: DispatchQueue

    /// Initialize a group of loggers
    ///
    /// - Parameter loggers: The initial loggers
    public init(loggers: [Logger] = []) {
        _loggers = loggers
        loggersDispatchQueue = DispatchQueue(label: "LoggerGroup")
    }

    /// The loggers forming the group
    public var loggers: [Logger] {
        var result: [Logger]?
        loggersDispatchQueue.sync {
            result = _loggers
        }
        return result!
    }

    /// Add a logger to the group
    ///
    /// - Parameter logger: A logger to add
    public func add(logger: Logger) {
        loggersDispatchQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            // Check if it is not already added
            guard self._loggers.contains(where: { $0 === logger }) == false else {
                return
            }
            // Set the group level if present
            if let groupLogLevel = self.groupLogLevel {
                logger.setLogLevel(groupLogLevel)
            }
            // Add the logger
            self._loggers.append(logger)
        }
    }

    /// Removes a logger from the group if present
    ///
    /// - Parameter logger: The logger to remove
    public func remove(logger: Logger) {
        loggersDispatchQueue.async(flags: .barrier) { [weak self] in
            self?._loggers.removeAll(where: { $0 === logger })
        }
    }

    /// Set all group members log level
    ///
    /// - Parameter newLogLevel: The new log level to be applied
    public func set(groupLogLevel newLogLevel: Logger.LogLevel) {
        loggersDispatchQueue.async(flags: .barrier) { [weak self] in
            self?.groupLogLevel = newLogLevel
            self?._loggers.forEach { $0.setLogLevel(newLogLevel) }
        }
    }
}
