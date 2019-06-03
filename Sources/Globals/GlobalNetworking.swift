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
    // MARK: - Activity Tracking

    /// The global network activity tracker instance
    static let global = UBNetworkActivityTracker()

    /// The global network activity state
    public static var globalNetworkActivityState: UBNetworkActivityTracker.NetworkActivityState {
        return global.networkActivityState
    }

    /// Add an observer for the state of the global network activity
    ///
    /// - Parameter block: The block to be called when the state changes
    public static func addGlobalNetworkActivityStateObserver(_ block: @escaping UBNetworkActivityTracker.StateObservationBlock) {
        return global.addStateObserver(block)
    }

    /// Adds a task for the global network activity.
    ///
    /// - Parameter task: The task to add.
    public static func addToGlobalNetworkActivity(_ task: UBURLDataTask) {
        global.add(task)
    }

    /// Removes a task from global network activity
    ///
    /// - Parameter task: The task to remove
    public static func removeFromGlobalNetworkActivity(_ task: UBURLDataTask) {
        global.remove(task)
    }

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

    // MARK: - Task Tracking

    /// The number of data tasks alive
    public static var numberOfDataTasks: Int {
        return global.numberOfTrackedTasks
    }
}
