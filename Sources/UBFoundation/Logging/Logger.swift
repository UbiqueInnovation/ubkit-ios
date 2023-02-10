//
//  Logger.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 17.03.19.
//  Copyright © 2019 Ubique. All rights reserved.
//

import Foundation
import os.log

public protocol UBLoggerListener: AnyObject {
    func log(message: String)
}

/// A logger wrapper for the OSLog that provide an easy way to log. The UBLogger is thread safe.
public class UBLogger {
    /// The logger to use
    private let logger: OSLog

    /// Thread safety
    private let logLevelDispatchQueue: DispatchQueue

    public weak static var listener: UBLoggerListener?

    // MARK: - Properties

    /// The backing value of the log level
    private var _logLevel: LogLevel = .default

    private var category: String?

    /// The log level of the logger
    public var logLevel: LogLevel {
        var result: LogLevel?
        logLevelDispatchQueue.sync {
            result = _logLevel
        }
        return result!
    }

    /// Set the log level of the logger
    ///
    /// - Parameter newLogLevel: The new log level
    public func setLogLevel(_ newLogLevel: LogLevel) {
        logLevelDispatchQueue.async(flags: .barrier) { [weak self] in
            self?._logLevel = newLogLevel
        }
    }

    // MARK: - Initializers

    /// Initalizes the logger with a OSLog
    ///
    /// - Parameter logger: The OSLog to use
    public init(_ logger: OSLog) {
        self.logger = logger
        logLevelDispatchQueue = DispatchQueue(label: "UBLogger")
    }

    /// Initalizes the logger with category and bundle
    ///
    /// - Parameters:
    ///   - category: The category to log. _Example: use Networking as a category for all networking activity logging_
    ///   - bundle: The bundle to use
    /// - Throws: `UBLoggingError` in case of failure
    public convenience init(category: String, bundle: Bundle = .main) throws {
        guard let bundleIdentifier = bundle.bundleIdentifier else {
            throw UBLoggingError.bundelIdentifierNotFound
        }
        let osLog = OSLog(subsystem: bundleIdentifier, category: category)
        self.init(osLog)
        self.category = category
    }

    // MARK: - Log a message

    /// Logs a message
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - type: The type of the message
    ///   - accessLevel: The access level of the message
    ///   - fileName: The file from where the log was called
    ///   - functionName: The function from where the log was called
    ///   - lineNumber: The line from where the log was called
    private func log(message: String, type: OSLogType, accessLevel: AccessLevel = .private, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        switch (accessLevel, logLevel) {
            case (_, .none):
                // No logs
                break
            case (.private, .verbose):
                // Get the name of the file
                let file = URL(fileURLWithPath: fileName).lastPathComponent
                // Get the line number
                let line = String(lineNumber)
                // Get the thread name
                let threadName = getCurrentThreadDescription()
                // Log the message and extra information
                os_log("[%{private}@] [%{private}@:%{private}@ %{private}@] > %{private}@", log: logger, type: type, threadName, file, line, functionName, message)

                let message = "\(self.category != nil ? "[\(self.category!)] " : "")[\(type.string)] [\(threadName):\(file) \(line)] > \(functionName) \(message)"
                Self.listener?.log(message: message)
            case (.private, .default):
                // Log only the message
                os_log("%{private}@", log: logger, type: type, message)
                Self.listener?.log(message: message)
            case (.public, .verbose):
                // Get the name of the file
                let file = URL(fileURLWithPath: fileName).lastPathComponent
                // Get the line number
                let line = String(lineNumber)
                // Get the thread name
                let threadName = getCurrentThreadDescription()
                // Log the message and extra information
                os_log("[%{public}@] [%{public}@:%{public}@ %{public}@] > %{public}@", log: logger, type: type, threadName, file, line, functionName, message)

                let message = "\(self.category != nil ? "[\(self.category!)] " : "")[\(type.string)] [\(threadName):\(file) \(line)] > \(functionName) \(message)"
                Self.listener?.log(message: message)
            case (.public, .default):
                // Log only the message
                os_log("%{public}@", log: logger, type: type, message)

                let message = "\(self.category != nil ? "[\(self.category!)] " : "")\(message)"
                Self.listener?.log(message: message)
        }
    }

    /// Log an info level message.
    ///
    /// - Parameters:
    ///   - subject: The subject to log
    ///   - accessLevel: The sensitivity of the information logged
    ///   - fileName: The file from where the log was called
    ///   - functionName: The function from where the log was called
    ///   - lineNumber: The line from where the log was called
    public func info<Subject>(_ subject: Subject, accessLevel: AccessLevel = .private, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        log(message: String(describing: subject), type: .info, accessLevel: accessLevel, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }

    /// Log an error level message.
    ///
    /// - Parameters:
    ///   - subject: The subject to log
    ///   - accessLevel: The sensitivity of the information logged
    ///   - fileName: The file from where the log was called
    ///   - functionName: The function from where the log was called
    ///   - lineNumber: The line from where the log was called
    public func error<Subject>(_ subject: Subject, accessLevel: AccessLevel = .private, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        log(message: String(describing: subject), type: .error, accessLevel: accessLevel, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }

    /// Log an debug level message.
    ///
    /// - Parameters:
    ///   - subject: The subject to log
    ///   - accessLevel: The sensitivity of the information logged
    ///   - fileName: The file from where the log was called
    ///   - functionName: The function from where the log was called
    ///   - lineNumber: The line from where the log was called
    public func debug<Subject>(_ subject: Subject, accessLevel: AccessLevel = .private, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        log(message: String(describing: subject), type: .debug, accessLevel: accessLevel, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }
}

public extension UBLogger {
    // MARK: - Access Level

    /// The access level of the log
    enum AccessLevel {
        /// Use public for no sensitive data
        case `public`
        /// Use private for sensitive data
        case `private`
    }

    // MARK: - Log Level

    /// The log level
    enum LogLevel {
        /// This will ensure a minimum log. Only the message is logged
        case `default`
        /// This will log extra information about the thread, file, method and line number of each log
        case verbose
        /// No logs at all
        case none
    }
}

extension UBLogger {
    /// :nodoc:
    private func getCurrentThreadDescription() -> String {
        if Thread.current.isMainThread {
            return "main"
        }
        if let name = Thread.current.name, name.isEmpty == false {
            return name
        }
        do {
            // A thread description is as follow: <NSThread: 0x7fa67851c660>{number = 2, name = (null)}
            // We use a regex to match the number and extract it
            let desc = String(describing: Thread.current)
            let regex = try NSRegularExpression(pattern: "number = [0-9]+")
            let results = regex.matches(in: desc, range: NSRange(desc.startIndex..., in: desc))
            guard let first = results.first, let range = Range(first.range, in: desc) else {
                return "Unknown"
            }
            let threadNumber = String(desc[range].replacingOccurrences(of: "number = ", with: ""))
            return "Thread \(threadNumber)"
        } catch {
            return "Unknown"
        }
    }
}

extension OSLogType {
    var string: String {
        switch self {
            case .debug: return "debug"
            case .error: return "error"
            case .fault: return "fault"
            case .info: return "info"
            default:
                return "default"
        }
    }
}
