//
//  CronRule.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 30.03.19.
//

import Foundation

public protocol CronRule {
    var repeatRule: CronRepeatRule { get }
    var deadlineFromNow: DispatchTimeInterval { get }
    var tolerence: DispatchTimeInterval? { get }
}

extension CronRule {
    public var isDeadlineInThePast: Bool {
        if repeatRule == .never, let interval = deadlineFromNow.timeInterval {
            return interval < 0
        } else {
            return false
        }
    }
}

public enum CronRepeatRule: Equatable {
    case never
    case after(DispatchTimeInterval)
}

public struct FireAtDateRule: CronRule {
    public var repeatRule: CronRepeatRule {
        return .never
    }

    public var deadlineFromNow: DispatchTimeInterval {
        return date.timeIntervalSinceNow.dispatchTimeInterval
    }

    public var tolerence: DispatchTimeInterval?

    private let date: Date
    public init(_ date: Date, tolerence: DispatchTimeInterval? = nil) {
        self.date = date
        self.tolerence = tolerence
    }

    public init(_ date: Date, tolerence: TimeInterval) {
        self.init(date, tolerence: tolerence.dispatchTimeInterval)
    }
}

public struct FireAtIntervalRule: CronRule {
    public var repeatRule: CronRepeatRule

    public var deadlineFromNow: DispatchTimeInterval {
        return interval.dispatchTimeInterval
    }

    public var tolerence: DispatchTimeInterval?

    private let interval: TimeInterval

    public init(_ interval: TimeInterval, repeat isRepeating: Bool = false, tolerence: DispatchTimeInterval? = nil) {
        assert((isRepeating && interval > 0) || !isRepeating)
        repeatRule = isRepeating ? .after(interval.dispatchTimeInterval) : .never
        self.tolerence = tolerence
        self.interval = interval
    }

    public init(_ interval: TimeInterval, repeat isRepeating: Bool = false, tolerence: TimeInterval) {
        self.init(interval, repeat: isRepeating, tolerence: tolerence.dispatchTimeInterval)
    }
}

private extension TimeInterval {
    var dispatchTimeInterval: DispatchTimeInterval {
        return DispatchTimeInterval.milliseconds(Int(self * 1000))
    }
}

private extension DispatchTimeInterval {
    var timeInterval: TimeInterval? {
        switch self {
        case .never:
            return nil
        case let .seconds(value):
            return TimeInterval(value)
        case let .milliseconds(value):
            return TimeInterval(value) * 0.001
        case let .microseconds(value):
            return TimeInterval(value) * 0.000001
        case let .nanoseconds(value):
            return TimeInterval(value) * 0.000000001
        }
    }
}
