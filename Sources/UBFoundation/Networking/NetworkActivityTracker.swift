//
//  NetworkActivityTracker.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 31.03.19.
//

import Foundation

/// A tracker that display an aggregated status of multiple DataTasks
public class UBNetworkActivityTracker {
    // MARK: - Definitions

    /// The status observation block.
    public typealias StateObservationBlock = (NetworkActivityState) -> Void

    /// The state of the network activity.
    public enum NetworkActivityState: Equatable {
        /// No active network connections
        case idle
        /// There is minimum one active network connection
        case fetching
    }

    // MARK: - Properties

    /// :nodoc:
    private var trackedTasks: NSHashTable<UBURLDataTask>
    /// :nodoc:
    private let serialQueue: DispatchQueue
    /// :nodoc:
    private var stateObservers: [StateObservationBlock]
    /// :nodoc:
    private var taskCreationObservers: [(UBURLDataTask) -> Void]
    /// :nodoc:
    public var callbackQueue: OperationQueue?

    /// The current state of the network activity of all the added tasks.
    public private(set) var networkActivityState: NetworkActivityState = .idle {
        didSet {
            guard networkActivityState != oldValue else {
                return
            }
            // Only notify when the state changes
            notifyObservers()
        }
    }

    // MARK: - Initializers

    /// Initializes a tracker.
    public init() {
        serialQueue = DispatchQueue(label: "Network Activity Tracker")
        stateObservers = []
        taskCreationObservers = []
        trackedTasks = NSHashTable<UBURLDataTask>(options: [.weakMemory])
    }

    /// The number of tracked tasks
    public var numberOfTrackedTasks: Int {
        trackedTasks.allObjects.count
    }

    // MARK: - Task addition and removal

    /// Add a task to be monitored for network activity.
    ///
    /// - Parameter task: The task to be monitored.
    public func add(_ task: UBURLDataTask) {
        serialQueue.sync {
            trackedTasks.add(task)
            taskCreationObservers.forEach { $0(task) }
        }
        updateState()
        task.addStateTransitionObserver { [weak self] _, _, _ in
            self?.updateState()
        }
    }

    /// Removes a task from contributing to the network activity.
    ///
    /// - Parameter task: The task to be removed.
    public func remove(_ task: UBURLDataTask) {
        serialQueue.sync {
            trackedTasks.remove(task)
        }
        updateState()
    }

    /// :nodoc:
    private func updateState() {
        serialQueue.sync {
            let isFetching = self.trackedTasks.allObjects.reduce(into: false) { $0 = $0 || ($1.state == .fetching) }
            self.networkActivityState = isFetching ? .fetching : .idle
        }
    }

    // MARK: - State Observation

    /// Add an observer that gets called when the state of the network activity changes.
    ///
    /// - Parameter block: The block to be executed when the network activity state changes
    public func addStateObserver(_ block: @escaping UBNetworkActivityTracker.StateObservationBlock) {
        serialQueue.sync {
            // Pass the current status to the block when added
            if let callbackQueue = callbackQueue {
                let state = self.networkActivityState
                callbackQueue.addOperation {
                    block(state)
                }
            } else {
                block(networkActivityState)
            }

            // Add the block to the list of observers
            stateObservers.append(block)
        }
    }

    public func addTaskCreationObserver(_ block: @escaping (UBURLDataTask) -> Void) {
        serialQueue.sync {
            taskCreationObservers.append(block)
        }
    }

    /// :nodoc:
    private func notifyObservers() {
        if let callbackQueue = callbackQueue {
            let state = networkActivityState
            callbackQueue.addOperation { [weak self] in
                self?.stateObservers.forEach { $0(state) }
            }
        } else {
            stateObservers.forEach { $0(networkActivityState) }
        }
    }
}
