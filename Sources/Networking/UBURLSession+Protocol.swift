//
//  UBURLSession+Protocol.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// An protocol that coordinates a group of related network data transfer tasks.
public protocol UBURLSessionProtocol {

    // MARK: - Managing the Session

    /// Invalidates the session, allowing any outstanding tasks to finish.
    func finishTasksAndInvalidate()

    /// Cancels all outstanding tasks and then invalidates the session.
    func invalidateAndCancel()

    /// Empties all cookies, caches and credential stores, removes disk files, flushes in-progress downloads to disk, and ensures that future requests occur on a new socket.
    ///
    /// - Parameter completionHandler: The completion handler to call when the reset operation is complete. This handler is executed on the delegate queue.
    func reset(completionHandler: @escaping () -> Void)
}

/// A data task capable session
public protocol DataTaskURLSession: UBURLSessionProtocol {
    /// Creates a task that retrieves the contents of a URL based on the specified URL request object, and calls a handler upon completion.
    ///
    /// - Parameters:
    ///   - request: The request to be executed
    ///   - owner: A Data Task that owns the request
    /// - Returns: The new session data task. Nil if there is no need for one.
    func dataTask(with request: UBURLRequest, owner: UBURLDataTask) -> URLSessionDataTask?
}
