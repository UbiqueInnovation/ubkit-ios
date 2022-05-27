//
//  UBURLSession.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

/// An object that coordinates a group of related network data transfer tasks.
public class UBURLSession: UBDataTaskURLSession {
    /// The underlaying session
    private let urlSession: URLSession

    /// The session delegate handeling everything
    // swiftlint:disable weak_delegate
    private let sessionDelegate: UBURLSessionDelegate
    // swiftlint:enable weak_delegate

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
        // Only if not a refresh task
        guard owner.flags.contains(.ignoreCache) == false,
              let cacheResult = sessionDelegate.cachingLogic?.cachedResponse(urlSession, request: request.getRequest(), dataTask: owner) else {
            return createTask(request.getRequest())
        }

        switch (urlSession.configuration.requestCachePolicy, cacheResult) {
            case (.reloadIgnoringLocalAndRemoteCacheData, _),
                 (.reloadIgnoringLocalCacheData, _),
                 (.reloadRevalidatingCacheData, .miss),
                 (.useProtocolCachePolicy, .miss),
                 (.returnCacheDataElseLoad, .miss):

                owner.completionHandlersDispatchQueue.sync {
                    sessionDelegate.cachingLogic?.hasMissedCache(dataTask: owner)
                }
                return createTask(request.getRequest())

            case let (.useProtocolCachePolicy, .hit(cachedResponse: cachedResponse, reloadHeaders: _, metrics: metrics)),
                 let (.returnCacheDataDontLoad, .hit(cachedResponse: cachedResponse, reloadHeaders: _, metrics: metrics)),
                 let (.returnCacheDataElseLoad, .hit(cachedResponse: cachedResponse, reloadHeaders: _, metrics: metrics)),
                 let (.returnCacheDataElseLoad, .expired(cachedResponse: cachedResponse, reloadHeaders: _, metrics: metrics)):
                #if os(watchOS)
                    let info = UBNetworkingTaskInfo(cacheHit: true, refresh: false)
                #else
                    let info = UBNetworkingTaskInfo(metrics: nil, cacheHit: true, refresh: false)
                #endif

                owner.dataTaskCompleted(data: cachedResponse.data, response: cachedResponse.response as? HTTPURLResponse, error: nil, info: info)
                owner.completionHandlersDispatchQueue.sync {
                    if let response = cachedResponse.response as? HTTPURLResponse {
                        sessionDelegate.cachingLogic?.hasUsed(response: response, metrics: metrics, request: request.getRequest(), dataTask: owner)
                    }
                }
                return nil

            case (.returnCacheDataDontLoad, .expired(cachedResponse: _, reloadHeaders: _, metrics: _)),
                 (.returnCacheDataDontLoad, .miss):
                sessionDelegate.cachingLogic?.hasMissedCache(dataTask: owner)
                owner.completionHandlersDispatchQueue.sync {
                    owner.dataTaskCompleted(data: nil, response: nil, error: UBInternalNetworkingError.noCachedData, info: nil)
                }
                return nil

            case let (.useProtocolCachePolicy, .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: _)),
                 let (.reloadRevalidatingCacheData, .expired(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: _)),
                 let (.reloadRevalidatingCacheData, .hit(cachedResponse: cachedResponse, reloadHeaders: reloadHeaders, metrics: _)):
                var reloadRequest = request.getRequest()
                for header in reloadHeaders {
                    reloadRequest.setValue(header.value, forHTTPHeaderField: header.key)
                }
                owner.completionHandlersDispatchQueue.sync {
                    sessionDelegate.cachingLogic?.hasMissedCache(dataTask: owner)
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
