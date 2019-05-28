//
//  GlobalNetworking.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 31.03.19.
//

import Foundation

/// The global network activity tracker instance
private let globalNetworkActivityTracker = UBNetworkActivityTracker()

// MARK: - Network Activity

/// A name space for networking
public enum Networking {
    /// The global network activity state
    public static var globalNetworkActivityState: UBNetworkActivityTracker.NetworkActivityState {
        return globalNetworkActivityTracker.networkActivityState
    }

    /// Add an observer for the state of the global network activity
    ///
    /// - Parameter block: The block to be called when the state changes
    public static func addGlobalNetworkActivityStateObserver(_ block: @escaping UBNetworkActivityTracker.StateObservationBlock) {
        return globalNetworkActivityTracker.addStateObserver(block)
    }

    /// Adds a task for the global network activity.
    ///
    /// - Parameter task: The task to add.
    public static func addToGlobalNetworkActivity(_ task: UBURLDataTask) {
        globalNetworkActivityTracker.add(task)
    }

    /// Removes a task from global network activity
    ///
    /// - Parameter task: The task to remove
    public static func removeFromGlobalNetworkActivity(_ task: UBURLDataTask) {
        globalNetworkActivityTracker.remove(task)
    }
}
