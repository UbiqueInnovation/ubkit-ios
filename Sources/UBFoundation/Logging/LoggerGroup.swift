//
//  LoggerGroup.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 17.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

/// A group of loggers. The UBLoggerGroup is thread safe
public class UBLoggerGroup {
    /// The backing data of the group
    private var _loggers: [UBLogger]

    /// The group log level
    private var groupLogLevel: UBLogger.LogLevel?

    /// Thread safety
    private let loggersDispatchQueue: DispatchQueue

    /// Initialize a group of loggers
    ///
    /// - Parameter loggers: The initial loggers
    public init(loggers: [UBLogger] = []) {
        _loggers = loggers
        loggersDispatchQueue = DispatchQueue(label: "UBLoggerGroup")
    }

    /// The loggers forming the group
    public var loggers: [UBLogger] {
        var result: [UBLogger]?
        loggersDispatchQueue.sync {
            result = _loggers
        }
        return result!
    }

    /// Add a logger to the group
    ///
    /// - Parameter logger: A logger to add
    public func add(logger: UBLogger) {
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
    public func remove(logger: UBLogger) {
        loggersDispatchQueue.async(flags: .barrier) { [weak self] in
            self?._loggers.removeAll(where: { $0 === logger })
        }
    }

    /// Set all group members log level
    ///
    /// - Parameter newLogLevel: The new log level to be applied
    public func set(groupLogLevel newLogLevel: UBLogger.LogLevel) {
        loggersDispatchQueue.async(flags: .barrier) { [weak self] in
            self?.groupLogLevel = newLogLevel
            self?._loggers.forEach { $0.setLogLevel(newLogLevel) }
        }
    }
}
#endif
