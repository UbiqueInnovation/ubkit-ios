//
//  NetworkTaskRecovery+OptionRetry.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 02.04.19.
//

import Foundation

/// Attempts to recover a network task by retrying the request
public struct RetryNeworkTaskRecoveryOption: NetworkTaskRecoveryOption {
    /// :nodoc:
    public var localizedDisplayName: String {
        return "Networking_Recovery_Retry_DisplayName".frameworkLocalized
    }
    
    /// :nodoc:
    private weak var networkTask: UBNetworkingTask?
    
    /// :nodoc:
    init(networkTask: UBNetworkingTask) {
        self.networkTask = networkTask
    }
    
    /// :nodoc:
    public func attemptRecovery(resultHandler: @escaping (Bool) -> Void) {
        networkTask?.start()
        resultHandler(true)
    }
    
    /// :nodoc:
    public func cancelOngoingRecovery() {
        networkTask?.cancel()
    }
}
