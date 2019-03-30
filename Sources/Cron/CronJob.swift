//
//  CronJob.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 26.03.19.
//

import Foundation

public class CronJob {
    /// A cron execution block
    public typealias ExecutionBlock = () -> Void
    /// Internal identifier
    private let identifier: UUID
    /// Dispatch queue
    private let dispatchQueue: DispatchQueue
    /// Syncronization
    private let serialQueue: DispatchQueue

    /// Internal GCD Timer with the corresponding fire mode
    private var timer: DispatchSourceTimer?
    private var rule: CronRule?

    /// The state
    private var state: State = .initial {
        willSet {
            assert(state != newValue)
        }
    }

    /// The block to be executed
    public private(set) var executionBlock: ExecutionBlock

    /// The name of the task
    public var name: String?

    public convenience init(fireAfter interval: TimeInterval, repeat isRepeating: Bool = false, qos: DispatchQoS = DispatchQoS.default, executionBlock: @escaping ExecutionBlock) {
        self.init(rule: FireAtIntervalRule(interval, repeat: isRepeating), qos: qos, executionBlock: executionBlock)
    }

    public convenience init(fireAt date: Date, qos: DispatchQoS = DispatchQoS.default, executionBlock: @escaping ExecutionBlock) {
        self.init(rule: FireAtDateRule(date), qos: qos, executionBlock: executionBlock)
    }

    public convenience init(rule: CronRule, qos: DispatchQoS = DispatchQoS.default, executionBlock: @escaping ExecutionBlock) {
        self.init(qos: qos, executionBlock: executionBlock)
        setRule(rule)
        resume()
    }

    public init(qos: DispatchQoS = DispatchQoS.default, executionBlock: @escaping ExecutionBlock) {
        self.identifier = UUID()
        self.executionBlock = executionBlock
        self.dispatchQueue = DispatchQueue(label: "Cron Job Callback \(identifier.uuidString)", qos: qos)
        self.serialQueue = DispatchQueue(label: "Cron Job Serial \(identifier.uuidString)", qos: qos)
    }

    deinit {
        if state == .paused || state == .initial {
            timer?.cancel()
            timer?.resume()
        }
    }

    private weak var _callbackQueue: OperationQueue?
    // The callback queue for the execution Block. If non is specified then it is executed on a secondary thread with the same Quality of service as the Cron Job.
    public var callbackQueue: OperationQueue? {
        get {
            var q: OperationQueue?
            serialQueue.sync {
                q = _callbackQueue
            }
            return q
        }
        set {
            serialQueue.sync {
                _callbackQueue = newValue
            }
        }
    }

    public func setExecutionBlock(_ newValue: @escaping ExecutionBlock) {
        serialQueue.sync {
            self.executionBlock = newValue
        }
    }

    public func setFireAt(_ date: Date) {
        setRule(FireAtDateRule(date))
    }

    public func setFireAfter(_ interval: TimeInterval, repeat isRepeating: Bool = false) {
        setRule(FireAtIntervalRule(interval, repeat: isRepeating))
    }

    public func setRule(_ rule: CronRule) {
        serialQueue.sync {
            let newTimer = createTimer(fireRule: rule)
            self.timer = newTimer
            self.rule = rule
            if state == .resumed {
                newTimer.resume()
            } else if state != .initial {
                state = .initial
            }
        }
    }

    public func resume() {
        serialQueue.sync {
            guard let timer = timer else {
                return
            }
            if state == .paused || state == .initial {
                state = .resumed
                timer.resume()
            }
        }
    }

    public func pause() {
        serialQueue.sync {
            if state == .resumed {
                state = .paused
                timer?.suspend()
            }
        }
    }
}

extension CronJob {
    private func createTimer(fireRule: CronRule) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: dispatchQueue)
        let deadline: DispatchWallTime = DispatchWallTime.now() + fireRule.deadlineFromNow
        switch (fireRule.repeatRule, fireRule.tolerence) {
        case (.never, .none):
            timer.schedule(wallDeadline: deadline, repeating: .never)
        case (let .after(interval), .none):
            timer.schedule(wallDeadline: deadline, repeating: interval, leeway: .never)
        case let (.never, .some(leeway)):
            timer.schedule(wallDeadline: deadline, repeating: .never, leeway: leeway)
        case let (.after(interval), .some(leeway)):
            timer.schedule(wallDeadline: deadline, repeating: interval, leeway: leeway)
        }

        timer.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }

            self.serialQueue.sync {
                self.executeBlock()
            }
        }

        return timer
    }

    private func executeBlock() {
        if let rule = self.rule, rule.repeatRule == CronRepeatRule.never {
            self.state = .finished
        }
        if let callbackQueue = self._callbackQueue {
            callbackQueue.addOperation { [weak self] in
                self?.executionBlock()
            }
        } else {
            self.executionBlock()
        }
    }
}

extension CronJob {
    private enum State: CustomDebugStringConvertible {
        case initial
        case paused
        case resumed
        case finished
        var debugDescription: String {
            switch self {
            case .initial:
                return "Initial"
            case .resumed:
                return "Resumed"
            case .paused:
                return "Paused"
            case .finished:
                return "Finished"
            }
        }
    }
}

extension CronJob: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Cron Job <\(name ?? identifier.uuidString)> \(state)"
    }
}

extension CronJob: Hashable {
    public static func == (lhs: CronJob, rhs: CronJob) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
