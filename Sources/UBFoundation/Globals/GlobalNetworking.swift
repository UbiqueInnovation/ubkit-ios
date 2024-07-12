//
//  GlobalNetworking.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 31.03.19.
//

import Foundation

// MARK: - Network Activity

/// A name space for networking
public enum Networking {
    // MARK: - Shared sessions

    /// A shared session that has a priority of responsive data. Useful for user initiated requests.
    public static let sharedSession: UBURLSession = {
        let queue = OperationQueue()
        queue.name = "UBURLSession Shared"
        queue.qualityOfService = .userInitiated
        let configuration = UBURLSessionConfiguration()
        configuration.sessionConfiguration.networkServiceType = .responsiveData
        return UBURLSession(configuration: configuration, delegateQueue: queue)
    }()

    /// A shared session that has a priority of background. Useful for low priority requests.
    public static let sharedLowPrioritySession: UBURLSession = {
        let queue = OperationQueue()
        queue.name = "UBURLSession Shared Background"
        queue.qualityOfService = .background
        let configuration = UBURLSessionConfiguration()
        configuration.sessionConfiguration.networkServiceType = .background
        return UBURLSession(configuration: configuration, delegateQueue: queue)
    }()
}
