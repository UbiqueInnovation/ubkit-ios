//
//  CronRule.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 30.03.19.
//

import Foundation

/// A rule for firing a cron job
public protocol UBCronRule {
    /// The rule to apply for repetition
    var repeatRule: UBCronRepeatRule { get }
    /// The deadline at which the job should fire after
    var deadlineFromNow: DispatchTimeInterval { get }
    /// The accepted tolerence around the firing date
    var tolerence: DispatchTimeInterval? { get }
}

/// The rule for repeating jobs
public enum UBCronRepeatRule: Equatable {
    /// Never repeat. This is a one time job
    case never
    /// Repeating job after a time interval
    case after(DispatchTimeInterval)
}

/// A single fire at a specific date
public struct UBFireAtDateRule: UBCronRule {
    /// :nodoc:
    public var repeatRule: UBCronRepeatRule {
        return .never
    }

    /// :nodoc:
    public var deadlineFromNow: DispatchTimeInterval {
        return date.timeIntervalSinceNow.dispatchTimeInterval
    }

    /// :nodoc:
    public var tolerence: DispatchTimeInterval?

    /// :nodoc:
    private let date: Date

    /// Create a rule that fires one time on a specific date
    ///
    /// - Parameters:
    ///   - date: The date to fire
    ///   - tolerence: The accepted tolerence with the firing date
    public init(_ date: Date, tolerence: DispatchTimeInterval? = nil) {
        self.date = date
        self.tolerence = tolerence
    }

    /// Create a rule that fires one time on a specific date
    ///
    /// - Parameters:
    ///   - date: The date to fire
    ///   - tolerence: The accepted tolerence with the firing date
    public init(_ date: Date, tolerence: TimeInterval) {
        self.init(date, tolerence: tolerence.dispatchTimeInterval)
    }
}

/// A rule that fires at a time interval and can repeat
public struct UBFireAtIntervalRule: UBCronRule {
    /// :nodoc:
    public var repeatRule: UBCronRepeatRule

    /// :nodoc:
    public var deadlineFromNow: DispatchTimeInterval {
        return interval.dispatchTimeInterval
    }

    /// :nodoc:
    public var tolerence: DispatchTimeInterval?

    /// :nodoc:
    private let interval: TimeInterval

    /// Create a rule that fires after the specified interval.
    ///
    /// - Parameters:
    ///   - interval: The minimum interval before firing
    ///   - isRepeating: If the job should keep repeat afterwards
    ///   - tolerence: The accepted tolerence with the firing date
    public init(_ interval: TimeInterval, repeat isRepeating: Bool = false, tolerence: DispatchTimeInterval? = nil) {
        assert((isRepeating && interval > 0) || !isRepeating)
        repeatRule = isRepeating ? .after(interval.dispatchTimeInterval) : .never
        self.tolerence = tolerence
        self.interval = interval
    }

    /// Create a rule that fires after the specified interval.
    ///
    /// - Parameters:
    ///   - interval: The minimum interval before firing
    ///   - isRepeating: If the job should keep repeat afterwards
    ///   - tolerence: The accepted tolerence with the firing date
    public init(_ interval: TimeInterval, repeat isRepeating: Bool = false, tolerence: TimeInterval) {
        self.init(interval, repeat: isRepeating, tolerence: tolerence.dispatchTimeInterval)
    }
}

private extension TimeInterval {
    /// :nodoc:
    var dispatchTimeInterval: DispatchTimeInterval {
        return DispatchTimeInterval.milliseconds(Int(self * 1000))
    }
}
