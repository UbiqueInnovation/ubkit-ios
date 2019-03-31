//
//  GlobalNetworking.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 31.03.19.
//

import Foundation

/// The global network activity tracker instance
private let globalNetworkActivityTracker = NetworkActivityTracker()

// MARK: - Network Activity

extension Networking {
    /// The global network activity state
    public static var globalNetworkActivityState: NetworkActivityTracker.NetworkActivityState {
        return globalNetworkActivityTracker.networkActivityState
    }

    /// Add an observer for the state of the global network activity
    ///
    /// - Parameter block: The block to be called when the state changes
    public static func addGlobalNetworkActivityStateObserver(_ block: @escaping NetworkActivityTracker.StateObservationBlock) {
        return globalNetworkActivityTracker.addStateObserver(block)
    }

    /// Adds a task for the global network activity.
    ///
    /// - Parameter task: The task to add.
    public static func addToGlobalNetworkActivity(_ task: HTTPDataTask) {
        globalNetworkActivityTracker.add(task)
    }

    /// Removes a task from global network activity
    ///
    /// - Parameter task: The task to remove
    public static func removeFromGlobalNetworkActivity(_ task: HTTPDataTask) {
        globalNetworkActivityTracker.remove(task)
    }
}
