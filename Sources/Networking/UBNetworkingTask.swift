//
//  UBNetworkingTask.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 02.04.19.
//

import Foundation

/// A task for networking
public protocol UBNetworkingTask: AnyObject {
    /// The request to execute. Setting this property will cancel any ongoing requests
    var request: UBURLRequest { get }
    /// An app-provided description of the current task.
    var taskDescription: String? { get }
    /// A representation of the overall task progress.
    var progress: Progress { get }
    /// Start the task with the given request
    func start()
    /// Cancel the current request
    func cancel()
}
