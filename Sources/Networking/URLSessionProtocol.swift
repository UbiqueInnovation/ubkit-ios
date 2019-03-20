//
//  URLSessionProtocol.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// An protocol that coordinates a group of related network data transfer tasks.
public protocol URLSessionProtocol {

    // MARK: - Creating a Session

    /// Creates a session with the specified session configuration.
    ///
    /// - Parameter configuration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, credential storage, and so on.
    init(configuration: URLSessionConfiguration)

    /// Creates a session with the specified session configuration, delegate, and operation queue.
    ///
    /// - Parameters:
    ///   - configuration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, and credential storage.
    ///   - delegate: A session delegate object that handles requests for authentication and other session-related events.
    ///   - queue: An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue, in order to ensure the correct ordering of callbacks. If nil, the session creates a serial operation queue for performing all delegate method calls and completion handler calls.
    init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue queue: OperationQueue?)

    // MARK: - Adding Data Tasks to a Session

    /// Creates a task that retrieves the contents of a URL based on the specified URL request object, and calls a handler upon completion.
    ///
    /// - Parameters:
    ///   - request: A URL request object that provides the URL, cache policy, request type, body data or body stream, and so on.
    ///   - completionHandler: The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
    /// - Returns: The new session data task.
    func dataTask(with request: HTTPURLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask

    // MARK: - Adding Download Tasks to a Session

    /// Creates a download task that retrieves the contents of a URL based on the specified URL request object, saves the results to a file, and calls a handler upon completion.
    ///
    /// - Parameters:
    ///   - request: A URL request object that provides the URL, cache policy, request type, body data or body stream, and so on.
    ///   - completionHandler: The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
    /// - Returns: The new session download task.
    func downloadTask(with request: HTTPURLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask

    /// Creates a download task to resume a previously canceled or failed download and calls a handler upon completion.
    ///
    /// - Parameters:
    ///   - resumeData: A data object that provides the data necessary to resume the download.
    ///   - completionHandler: The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
    /// - Returns: The new session download task.
    func downloadTask(withResumeData resumeData: Data, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask

    // MARK: - Adding Upload Tasks to a Session

    /// Creates a task that performs an HTTP request for the specified URL request object, uploads the provided data, and calls a handler upon completion.
    ///
    /// - Parameters:
    ///   - request: A URL request object that provides the URL, cache policy, request type, and so on. The body stream and body data in this request object are ignored.
    ///   - bodyData: The body data for the request.
    ///   - completionHandler: The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
    /// - Returns: The new session upload task.
    func uploadTask(with request: HTTPURLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask

    /// Creates a task that performs an HTTP request for uploading the specified file, then calls a handler upon completion.
    ///
    /// - Parameters:
    ///   - request: A URL request object that provides the URL, cache policy, request type, and so on. The body stream and body data in this request object are ignored.
    ///   - fileURL: The URL of the file to upload.
    ///   - completionHandler: The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
    /// - Returns: The new session upload task.
    func uploadTask(with request: HTTPURLRequest, fromFile fileURL: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask

    // MARK: - Managing the Session

    /// Asynchronously calls a completion callback with all tasks in a session
    ///
    /// - Parameter completionHandler: The completion handler to call with the list of tasks.
    func getAllTasks(completionHandler: @escaping ([URLSessionTask]) -> Void)

    /// Invalidates the session, allowing any outstanding tasks to finish.
    func finishTasksAndInvalidate()

    /// Cancels all outstanding tasks and then invalidates the session.
    func invalidateAndCancel()

    /// Empties all cookies, caches and credential stores, removes disk files, flushes in-progress downloads to disk, and ensures that future requests occur on a new socket.
    ///
    /// - Parameter completionHandler: The completion handler to call when the reset operation is complete. This handler is executed on the delegate queue.
    func reset(completionHandler: @escaping () -> Void)
}

// URLSession conforms to URLSessionProtocol
extension URLSession: URLSessionProtocol {
    /// :nodoc:
    public func dataTask(with request: HTTPURLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return dataTask(with: request.getRequest(), completionHandler: completionHandler)
    }

    /// :nodoc:
    public func downloadTask(with request: HTTPURLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return downloadTask(with: request.getRequest(), completionHandler: completionHandler)
    }

    /// :nodoc:
    public func uploadTask(with request: HTTPURLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        return uploadTask(with: request.getRequest(), from: bodyData, completionHandler: completionHandler)
    }

    /// :nodoc:
    public func uploadTask(with request: HTTPURLRequest, fromFile fileURL: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        return uploadTask(with: request.getRequest(), fromFile: fileURL, completionHandler: completionHandler)
    }
}
