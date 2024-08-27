//
//  CronJob.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 26.03.19.
//

import Foundation

/// A object that can schedule an invocation at a point in time.
public class UBCronJob {
    // MARK: - Definitions

    /// A cron execution block
    public typealias ExecutionBlock = () -> Void

    /// The state of the cron job
    public enum State: CustomDebugStringConvertible {
        /// The cron job is initialized and ready to run
        case initial
        /// The job was paused
        case paused
        /// The job is running
        case resumed
        /// The job has finished running
        case finished

        /// :nodoc:
        public var debugDescription: String {
            switch self {
                case .initial:
                    "Initial"
                case .resumed:
                    "Resumed"
                case .paused:
                    "Paused"
                case .finished:
                    "Finished"
            }
        }
    }

    // MARK: - Properties

    /// Internal identifier
    private let identifier: UUID
    /// Dispatch queue
    private let dispatchQueue: DispatchQueue
    /// Syncronization
    private let serialQueue: DispatchQueue
    /// Internal GCD Timer with the corresponding fire mode
    private var timer: DispatchSourceTimer?
    /// Current rule
    private var rule: UBCronRule?
    /// The state of the Job
    public private(set) var state: State = .initial {
        willSet {
            assert(state != newValue)
        }
    }

    /// The name of the task
    public var name: String?

    /// The backing data for the callback queue
    private weak var _callbackQueue: OperationQueue?

    /// The callback queue for the execution Block. If non is specified then it is executed on a secondary thread with the same Quality of service as the Cron Job.
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

    /// The backing execution block
    private var _executionBlock: ExecutionBlock

    /// The block to be executed by the job when fired
    public var executionBlock: ExecutionBlock {
        get {
            var ex: ExecutionBlock?
            serialQueue.sync {
                ex = _executionBlock
            }
            return ex!
        }
        set {
            serialQueue.sync {
                _executionBlock = newValue
            }
        }
    }

    // MARK: - Initializers

    /// Creates a cron job that will fire after the specified time interval. The job will start right away, no need to call resume.
    ///
    /// - Parameters:
    ///   - interval: The time interval before the job fires
    ///   - isRepeating: If the job is repeating
    ///   - qos: The quality of service of the job
    ///   - executionBlock: The block to be executed by the job
    public convenience init(fireAfter interval: TimeInterval, repeat isRepeating: Bool = false, qos: DispatchQoS = DispatchQoS.default, executionBlock: @escaping ExecutionBlock) {
        self.init(rule: UBFireAtIntervalRule(interval, repeat: isRepeating), qos: qos, executionBlock: executionBlock)
    }

    /// Creates a cron job that will fire at the specified date. The job will start right away, no need to call resume.
    ///
    /// - Parameters:
    ///   - date: The date when the job will fire
    ///   - qos: The quality of service of the job
    ///   - executionBlock: The block to be executed by the job
    public convenience init(fireAt date: Date, qos: DispatchQoS = DispatchQoS.default, executionBlock: @escaping ExecutionBlock) {
        self.init(rule: UBFireAtDateRule(date), qos: qos, executionBlock: executionBlock)
    }

    /// Creates a cron job with a fire rule. The job will start right away, no need to call resume.
    ///
    /// - Parameters:
    ///   - rule: The rule of firing
    ///   - qos: The quality of service of the job
    ///   - executionBlock: The block to be executed by the job
    public convenience init(rule: UBCronRule, qos: DispatchQoS = DispatchQoS.default, executionBlock: @escaping ExecutionBlock) {
        self.init(qos: qos, executionBlock: executionBlock)
        setRule(rule)
        resume()
    }

    /// Creates a cron job. The job will not start right away, you still need to call resume.
    ///
    /// - Parameters:
    ///   - qos: The quality of service of the job
    ///   - executionBlock: The block to be executed by the job
    public init(qos: DispatchQoS = DispatchQoS.default, executionBlock: @escaping ExecutionBlock) {
        identifier = UUID()
        _executionBlock = executionBlock
        dispatchQueue = DispatchQueue(label: "Cron Job Timer \(identifier.uuidString)", qos: qos)
        serialQueue = DispatchQueue(label: "Cron Job Serial \(identifier.uuidString)", qos: qos)
    }

    /// :nodoc:
    deinit {
        if state == .paused || state == .initial {
            timer?.cancel()
            // We need to call resume after cancel otherwise we will crash.
            timer?.resume()
        }
    }

    // - MARK: Manipulating the firing rule

    /// Set the fire date
    ///
    /// - Parameter date: The new fire date
    public func setFireAt(_ date: Date) {
        setRule(UBFireAtDateRule(date))
    }

    /// Set the fire interval
    ///
    /// - Parameters:
    ///   - interval: The new interval
    ///   - isRepeating: If the job should repeat
    public func setFireAfter(_ interval: TimeInterval, repeat isRepeating: Bool = false) {
        setRule(UBFireAtIntervalRule(interval, repeat: isRepeating))
    }

    /// Sets the rule of the job
    ///
    /// - Parameter rule: The new rule to follow for firing
    public func setRule(_ rule: UBCronRule) {
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

    // - MARK: Controling the job execution

    /// Resume or start an initial or paused job
    public func resume() {
        serialQueue.sync {
            guard let timer else {
                return
            }
            if state == .paused || state == .initial {
                state = .resumed
                timer.resume()
            }
        }
    }

    /// Pauses a resumed job
    public func pause() {
        serialQueue.sync {
            if state == .resumed {
                state = .paused
                timer?.suspend()
            }
        }
    }
}

extension UBCronJob {
    /// :nodoc:
    private func createTimer(fireRule: UBCronRule) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: dispatchQueue)
        let deadline: DispatchWallTime = DispatchWallTime.now() + fireRule.deadlineFromNow
        switch (fireRule.repeatRule, fireRule.tolerence) {
            case (.never, .none):
                timer.schedule(wallDeadline: deadline, repeating: .never)
            case let (.after(interval), .none):
                timer.schedule(wallDeadline: deadline, repeating: interval, leeway: .never)
            case let (.never, .some(leeway)):
                timer.schedule(wallDeadline: deadline, repeating: .never, leeway: leeway)
            case let (.after(interval), .some(leeway)):
                timer.schedule(wallDeadline: deadline, repeating: interval, leeway: leeway)
        }

        timer.setEventHandler { [weak self] in
            guard let self else {
                return
            }

            self.serialQueue.sync {
                self.executeBlock()
            }
        }

        return timer
    }

    /// :nodoc:
    private func executeBlock() {
        if let rule = self.rule, rule.repeatRule == UBCronRepeatRule.never {
            state = .finished
        }
        if let callbackQueue = _callbackQueue {
            callbackQueue.addOperation { [weak self] in
                self?._executionBlock()
            }
        } else {
            _executionBlock()
        }
    }
}

extension UBCronJob: CustomDebugStringConvertible {
    /// :nodoc:
    public var debugDescription: String {
        "Cron Job <\(name ?? identifier.uuidString)> \(state)"
    }
}

extension UBCronJob: Hashable {
    /// :nodoc:
    public static func == (lhs: UBCronJob, rhs: UBCronJob) -> Bool {
        lhs.identifier == rhs.identifier
    }

    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
