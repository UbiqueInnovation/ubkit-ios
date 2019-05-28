//
//  UBURLSession.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

/// An object that coordinates a group of related network data transfer tasks.
public class UBURLSession: UBDataTaskURLSession {
    /// A shared session that has a priority of responsive data. Useful for user initiated requests.
    public static let shared: UBURLSession = {
        let queue = OperationQueue()
        queue.name = "UBURLSession Shared"
        queue.qualityOfService = .userInitiated
        let configuration = UBURLSessionConfiguration()
        configuration.sessionConfiguration.networkServiceType = .responsiveData
        return UBURLSession(configuration: configuration, delegateQueue: queue)
    }()

    /// A shared session that has a priority of background. Useful for low priority requests.
    public static let sharedLowPriority: UBURLSession = {
        let queue = OperationQueue()
        queue.name = "UBURLSession Shared Background"
        queue.qualityOfService = .background
        let configuration = UBURLSessionConfiguration()
        configuration.sessionConfiguration.networkServiceType = .background
        return UBURLSession(configuration: configuration, delegateQueue: queue)
    }()

    /// The underlaying session
    private let urlSession: URLSession

    /// The session delegate handeling everything
    private let sessionDelegate: UBURLSessionDelegate

    // MARK: - Creating a Session

    /// Creates a session with the specified session configuration, delegate, and operation queue.
    ///
    /// - Parameters:
    ///   - configuration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, credential storage, and server trusts.
    ///   - delegate: A session delegate object that handles requests for authentication and other session-related events.
    ///   - queue: An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue, in order to ensure the correct ordering of callbacks. If nil, the session creates a serial operation queue for performing all delegate method calls and completion handler calls.
    public init(configuration: UBURLSessionConfiguration = UBURLSessionConfiguration(), delegateQueue queue: OperationQueue? = nil) {
        let sessionDelegate = UBURLSessionDelegate(configuration: configuration)
        urlSession = URLSession(configuration: configuration.sessionConfiguration, delegate: sessionDelegate, delegateQueue: queue)
        self.sessionDelegate = sessionDelegate
        sessionDelegate.urlSession = urlSession
    }

    /// :nodoc:
    deinit {
        invalidateAndCancel()
    }

    /// :nodoc:
    public func dataTask(with request: UBURLRequest, owner: UBURLDataTask) -> URLSessionDataTask? {
        // Creats and adds a data task to the delegate
        func createTask(_ request: URLRequest, cachedResponse: CachedURLResponse? = nil) -> URLSessionDataTask? {
            let sessionDataTask = urlSession.dataTask(with: request)
            sessionDelegate.addTaskPair(key: sessionDataTask, value: owner, cachedResponse: cachedResponse)
            return sessionDataTask
        }

        // Check if we have a caching logic otherwise return a task
        guard let cacheResult = sessionDelegate.cachingLogic?.cachedResponse(urlSession, request: request.getRequest(), dataTask: owner) else {
            return createTask(request.getRequest())
        }

        switch (urlSession.configuration.requestCachePolicy, cacheResult) {
        case (.reloadIgnoringLocalAndRemoteCacheData, _),
             (.reloadIgnoringLocalCacheData, _),
             (.reloadRevalidatingCacheData, .miss),
             (.useProtocolCachePolicy, .miss),
             (.returnCacheDataElseLoad, .miss):
            return createTask(request.getRequest())

        case let (.useProtocolCachePolicy, .hit(cachedResponse: cachedResponse, reloadHeaders: _)),
             let (.returnCacheDataDontLoad, .hit(cachedResponse: cachedResponse, reloadHeaders: _)),
             let (.returnCacheDataElseLoad, .hit(cachedResponse: cachedResponse, reloadHeaders: _)),
             let (.returnCacheDataElseLoad, .expired(cachedResponse: cachedResponse, reloadHeaders: _)):
            owner.dataTaskCompleted(data: cachedResponse.data, response: cachedResponse.response as? HTTPURLResponse, error: nil, info: UBNetworkingTaskInfo(metrics: nil, cacheHit: true))
            return nil

        case (.returnCacheDataDontLoad, .expired(cachedResponse: _, reloadHeaders: _)),
             (.returnCacheDataDontLoad, .miss):
            owner.dataTaskCompleted(data: nil, response: nil, error: UBNetworkingError.noCachedData, info: nil)
            return nil

        case let (.useProtocolCachePolicy, .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders)),
             let (.reloadRevalidatingCacheData, .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders)),
             let (.reloadRevalidatingCacheData, .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders)):
            var reloadRequest = request.getRequest()
            for header in reloadHeaders {
                reloadRequest.setValue(header.value, forHTTPHeaderField: header.key)
            }
            return createTask(reloadRequest, cachedResponse: cachedResponse)

        @unknown default:
            fatalError()
        }
    }

    /// :nodoc:
    public func finishTasksAndInvalidate() {
        urlSession.finishTasksAndInvalidate()
    }

    /// :nodoc:
    public func invalidateAndCancel() {
        urlSession.invalidateAndCancel()
    }

    /// :nodoc:
    public func reset(completionHandler: @escaping () -> Void) {
        urlSession.reset(completionHandler: completionHandler)
    }
}
