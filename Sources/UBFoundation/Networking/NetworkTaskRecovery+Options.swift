//
//  NetworkTaskRecovery+Options.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 02.04.19.
//

import Foundation

/// A set of options to recover from a network task failure
public struct UBNetworkTaskRecoveryOptions: RecoverableError, Equatable {
    /// The original error that the object try to recover from
    public let originalError: Error
    /// :nodoc:
    private let _recoveryOptions: [UBNetworkTaskRecoveryOption]
    /// Provides a set of possible recovery options to present to the user.
    public var recoveryOptions: [String] {
        return _recoveryOptions.map { $0.localizedDisplayName }
    }

    /// Creates a set of options to recover from a network task failure
    ///
    /// - Parameters:
    ///   - error: The original error that the object is recovering from
    ///   - recoveryOptions: The recovery options available to pic from
    public init(recoveringFrom error: Error, recoveryOptions: [UBNetworkTaskRecoveryOption]) {
        originalError = error
        _recoveryOptions = recoveryOptions
    }

    /// Attempt to recover from this error when the user selected the option at the given index. Returns true to indicate successful recovery, and false otherwise.
    public func attemptRecovery(optionIndex _: Int) -> Bool {
        fatalError("Serial recovery is not supported. Please use the attemptRecovery(optionIndex:, resultHandler:)")
    }

    /// Attempt to recover from this error when the user selected the option at the given index. Returns true to indicate successful recovery, and false otherwise.
    public func attemptRecovery(optionIndex recoveryOptionIndex: Int, resultHandler handler: @escaping (Bool) -> Void) {
        _recoveryOptions[recoveryOptionIndex].attemptRecovery(resultHandler: handler)
    }

    /// Cancels all ongoing recoveries stored in this object
    public func cancelOngoingRecovery() {
        _recoveryOptions.forEach { $0.cancelOngoingRecovery() }
    }

    public static func == (lhs: UBNetworkTaskRecoveryOptions, rhs: UBNetworkTaskRecoveryOptions) -> Bool {
        (lhs.originalError as NSError) == (rhs.originalError as NSError) &&
        lhs.recoveryOptions == rhs.recoveryOptions
    }

}
