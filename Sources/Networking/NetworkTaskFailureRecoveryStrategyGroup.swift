//
//  NetworkTaskFailureRecoveryStrategyGroup.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 02.04.19.
//

import Foundation

/// A group of data task failure recovery strategies
public class NetworkTaskFailureRecoveryStrategyGroup: NetworkingTaskFailureRecoveryStrategy {
    // - MARK: Properties

    /// :nodoc:
    private let serialStrategies = DispatchQueue(label: "Failure Recovery Strategies")
    /// :nodoc:
    private var _strategies: [NetworkingTaskFailureRecoveryStrategy]
    /// The list of recovery strategies in the group
    public var strategies: [NetworkingTaskFailureRecoveryStrategy] {
        return serialStrategies.sync {
            _strategies
        }
    }

    // - MARK: Initializers

    /// Initializes the group with strategies
    ///
    /// - Parameter strategies: The list of strategies to add in the group. Default to nothing
    public init(strategies: [NetworkingTaskFailureRecoveryStrategy] = []) {
        _strategies = strategies
    }

    /// :nodoc:
    deinit {
        cancelCurrentRecovery()
    }

    /// Add a strategy to the group
    ///
    /// - Parameter strategy: The strategy to add
    public func append(_ strategy: NetworkingTaskFailureRecoveryStrategy) {
        serialStrategies.sync {
            _strategies.append(strategy)
        }
    }

    /// :nodoc:
    private let serialOperation = DispatchQueue(label: "Failure Recovery Operation")
    /// :nodoc:
    private var currentRecovery: Recovery?
    /// Cancels the ongowing recovery
    public func cancelCurrentRecovery() {
        serialOperation.sync {
            currentRecovery?.cancelled = true
        }
    }

    /// :nodoc:
    public func recoverTask(_ dataTask: UBURLDataTask, data: Data?, response: URLResponse?, error: Error, completion: @escaping (NetworkingTaskFailureRecoveryResult) -> Void) {
        cancelCurrentRecovery()

        let newRecovery = Recovery()
        var strategies = ArraySlice<NetworkingTaskFailureRecoveryStrategy>()
        serialOperation.sync {
            currentRecovery = newRecovery
            strategies = ArraySlice(self.strategies)
        }

        recursiveRecoverTask(dataTask, data: data, response: response, error: error, recovery: newRecovery, strategies: strategies, completion: completion)
    }

    /// :nodoc:
    private func recursiveRecoverTask(_ dataTask: UBURLDataTask, data: Data?, response: URLResponse?, error: Error, recovery: Recovery, strategies: ArraySlice<NetworkingTaskFailureRecoveryStrategy>, completion: @escaping (NetworkingTaskFailureRecoveryResult) -> Void) {
        guard recovery.cancelled == false else {
            return
        }
        guard let strategy = strategies.first else {
            completion(.cannotRecover)
            return
        }

        strategy.recoverTask(dataTask, data: data, response: response, error: error) { [weak self] result in
            switch result {
            case .cannotRecover:
                self?.recursiveRecoverTask(dataTask, data: data, response: response, error: error, recovery: recovery, strategies: strategies.dropFirst(), completion: completion)
            default:
                completion(result)
            }
        }
    }
}

extension NetworkTaskFailureRecoveryStrategyGroup {
    /// This is used to convey cancellation information to the running task
    private class Recovery {
        /// :nodoc
        private let serial = DispatchQueue(label: "Group Recovery Object")
        /// :nodoc
        private var _cancelled: Bool = false
        /// :nodoc
        var cancelled: Bool {
            get {
                return serial.sync {
                    _cancelled
                }
            }
            set {
                serial.sync {
                    _cancelled = newValue
                }
            }
        }
    }
}
