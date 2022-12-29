//
//  NetworkTaskRecovery.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 02.04.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

/// The result of attempting a recovery after a network task fails
public enum UBNetworkingTaskRecoveryResult {
    /// The strategy has finished recovering and needs to restart the task
    case restartDataTask
    /// The strategy has finished successfully and could recover the data
    case recovered(data: Data?, response: HTTPURLResponse, info: UBNetworkingTaskInfo?)
    /// The strategy could offer different options of recovery
    case recoveryOptions(options: UBNetworkTaskRecoveryOptions)
    /// Cannot recover the failure
    case cannotRecover
}

/// Types that can recover a networking task failure. These objects are called after the validation process to allow for rectification. Once all strategies fails, then the completion block of the task fails. If one strategy finds a solution the no further strategies are called.
public protocol UBNetworkingTaskRecoveryStrategy {
    /// Attempts a recovery of the failed task.
    ///
    /// - Parameters:
    ///   - dataTask: The data task that failed
    ///   - data: The data returned
    ///   - response: The response returned
    ///   - error: The error returned
    ///   - completion: To be called when the recovery process is finished
    func recoverTask(_ dataTask: UBURLDataTask, data: Data?, response: URLResponse?, error: Error, completion: @escaping (UBNetworkingTaskRecoveryResult) -> Void)
}
#endif
