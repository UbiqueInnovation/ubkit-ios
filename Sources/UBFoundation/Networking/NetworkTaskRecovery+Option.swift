//
//  NetworkTaskRecovery+Option.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 02.04.19.
//

import Foundation

/// An option to recover from a network task failure
public protocol UBNetworkTaskRecoveryOption: Sendable {
    /// The localized name of the recovery
    var localizedDisplayName: String { get }
    /// Attempt to recover from the error.
    ///
    /// - Parameter resultHandler: Once the recovery finished. Parameter is to show if the recovery succeeded or failed.
    func attemptRecovery(resultHandler: @escaping (Bool) -> Void)
    /// Cancels the ongoing recovery if any is running.
    func cancelOngoingRecovery()
}
