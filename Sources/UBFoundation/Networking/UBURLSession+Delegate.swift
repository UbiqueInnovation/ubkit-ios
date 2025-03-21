//
//  UBURLSession+Delegate.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

/// An object defining methods that URL session instances call to handle task-level events.
final class UBURLSessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    /// Storage of the task mapping
    private nonisolated(unsafe) let tasks = NSMapTable<URLSessionTask, UBURLDataTask>(keyOptions: .weakMemory, valueOptions: .weakMemory)
    /// Storage of the task data
    private nonisolated(unsafe) let tasksData = NSMapTable<URLSessionTask, DataHolder>(keyOptions: .weakMemory, valueOptions: .strongMemory)

    private let serialQueue: DispatchQueue = DispatchQueue(label: "UBURLSessionDelegate")

    /// The url session, for verification purpouses
    private nonisolated(unsafe) weak var _urlSession: URLSession?
    private let urlSessionQueue = DispatchQueue(label: "UBURLSessionDelegate.urlsession")

    func setSession(_ session: URLSession?) {
        urlSessionQueue.sync {
            _urlSession = session
        }
    }

    /// The manager providing server trust verification
    private let serverTrustManager: UBServerTrustManager

    /// :nodoc:
    private let allowsRedirection: Bool

    /// :nodoc:
    let cachingLogic: UBCachingLogic?

    /// Initializes the delegate with a configuration
    ///
    /// - Parameter configuration: The configuration to use
    init(configuration: UBURLSessionConfiguration) {
        serverTrustManager = UBServerTrustManager(evaluators: configuration.hostsServerTrusts, default: configuration.defaultServerTrust)
        allowsRedirection = configuration.allowRedirections
        cachingLogic = configuration.cachingLogic
        super.init()
    }

    /// Adds a task pair to the list of monitored tasks.
    func addTaskPair(key: URLSessionTask, value: UBURLDataTask, cachedResponse: CachedURLResponse?) {
        serialQueue.sync {
            tasks.setObject(value, forKey: key)
            let dataHolder = DataHolder(key.originalRequest!)
            dataHolder.cached = cachedResponse
            tasksData.setObject(dataHolder, forKey: key)
        }
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        urlSessionQueue.sync {
            assert(session == self._urlSession, "The sessions are not matching")
        }

        var _ubDataTask: UBURLDataTask?
        var _collectedData: UBURLSessionDelegate.DataHolder?
        serialQueue.sync {
            _ubDataTask = tasks.object(forKey: task)
            _collectedData = tasksData.object(forKey: task)
        }

        guard let ubDataTask = _ubDataTask, ubDataTask.dataTask == task else {
            return
        }

        defer {
            // Clear the collected data
            serialQueue.sync {
                tasksData.removeObject(forKey: task)
                tasks.removeObject(forKey: task)
            }
        }

        guard let collectedData = _collectedData else {
            ubDataTask.dataTaskCompleted(data: nil, response: nil, error: error, info: nil)
            return
        }

        guard let response = collectedData.response as? HTTPURLResponse else {
            #if os(watchOS)
                let info = UBNetworkingTaskInfo(cacheHit: false, refresh: ubDataTask.flags.contains(.refresh))
            #else
                let info = UBNetworkingTaskInfo(metrics: collectedData.metrics, cacheHit: false, refresh: ubDataTask.flags.contains(.refresh))
            #endif
            ubDataTask.dataTaskCompleted(data: collectedData.data, response: nil, error: collectedData.error ?? error, info: info)
            return
        }

        // Return more specific error if available (collectedData.error holds original error before cancelling request)
        if let collectedError = collectedData.error {
            ubDataTask.dataTaskCompleted(data: collectedData.data, response: response, error: collectedError, info: nil)
            return
        }

        if let error {
            ubDataTask.dataTaskCompleted(data: collectedData.data, response: response, error: error, info: nil)
            return
        }

        // Execute the caching logic
        let cachedResponse = executeCachingLogic(cachingLogic: cachingLogic, session: session, task: task, ubDataTask: ubDataTask, request: collectedData.request, response: response, data: collectedData.data, metrics: collectedData.metrics, error: error)

        // If not modified return the cached data
        if response.statusCode == UBStandardHTTPCode.notModified, let cached = collectedData.cached {
            #if os(watchOS)
                let info = UBNetworkingTaskInfo(cacheHit: true, refresh: ubDataTask.flags.contains(.refresh))
            #else
                let info = UBNetworkingTaskInfo(metrics: collectedData.metrics, cacheHit: true, refresh: ubDataTask.flags.contains(.refresh))
            #endif

            // Update the cache if needed
            if let newCachedResponse = cachingLogic?.proposeUpdatedCachedResponse(cached, newResponse: response),
                let request = task.currentRequest
            {
                session.configuration.urlCache?.storeCachedResponse(newCachedResponse, for: request)
            }
            if !ubDataTask.flags.contains(.refresh) {
                ubDataTask.dataTaskCompleted(data: cached.data, response: cached.response as? HTTPURLResponse, error: collectedData.error ?? error, info: info)
            }
            if let response = cached.response as? HTTPURLResponse {
                cachingLogic?.hasUsed(cachedResponse: response, nonModifiedResponse: response, metrics: collectedData.metrics, request: collectedData.request, dataTask: ubDataTask)
            }
            return
        }

        // Make sure we do not process error status
        guard response.statusCode == UBHTTPCodeCategory.success else {
            let responseError: Error =
                if response.statusCode == UBHTTPCodeCategory.redirection, allowsRedirection == false {
                    UBInternalNetworkingError.requestRedirected
                } else {
                    UBInternalNetworkingError.requestFailed(httpStatusCode: response.statusCode)
                }
            #if os(watchOS)
                let info = UBNetworkingTaskInfo(cacheHit: false, refresh: ubDataTask.flags.contains(.refresh))
            #else
                let info = UBNetworkingTaskInfo(metrics: collectedData.metrics, cacheHit: false, refresh: ubDataTask.flags.contains(.refresh))
            #endif
            ubDataTask.dataTaskCompleted(data: collectedData.data, response: response, error: responseError, info: info)
            return
        }

        #if os(watchOS)
            let info = UBNetworkingTaskInfo(cacheHit: false, refresh: ubDataTask.flags.contains(.refresh))
        #else
            let info = UBNetworkingTaskInfo(metrics: collectedData.metrics, cacheHit: false, refresh: ubDataTask.flags.contains(.refresh))
        #endif
        ubDataTask.dataTaskCompleted(data: collectedData.data, response: response, error: collectedData.error ?? error, info: info)

        ubDataTask.completionHandlersDispatchQueue.sync {
            cachingLogic?.hasProposedCachedResponse(cachedURLResponse: cachedResponse, response: response, session: session, request: collectedData.request, ubDataTask: ubDataTask, metrics: collectedData.metrics)
        }
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        urlSessionQueue.sync {
            assert(session == self._urlSession, "The sessions are not matching")
        }

        var _collectedData: UBURLSessionDelegate.DataHolder?
        serialQueue.sync {
            _collectedData = tasksData.object(forKey: task)
        }

        guard let dataHolder = _collectedData else {
            return
        }
        dataHolder.metrics = metrics
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        urlSessionQueue.sync {
            assert(session == self._urlSession, "The sessions are not matching")
        }

        var _ubDataTask: UBURLDataTask?
        var _collectedData: UBURLSessionDelegate.DataHolder?
        serialQueue.sync {
            _ubDataTask = tasks.object(forKey: dataTask)
            _collectedData = tasksData.object(forKey: dataTask)
        }

        guard let ubDataTask = _ubDataTask, ubDataTask.dataTask == dataTask, let dataHolder = _collectedData else {
            completionHandler(.cancel)
            return
        }

        dataHolder.response = response

        guard let httpRespnse = response as? HTTPURLResponse else {
            dataHolder.error = UBInternalNetworkingError.notHTTPResponse
            completionHandler(.cancel)
            return
        }

        do {
            try ubDataTask.validate(response: httpRespnse)
            completionHandler(.allow)
        } catch {
            dataHolder.error = error
            completionHandler(.cancel)
        }
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        urlSessionQueue.sync {
            assert(session == self._urlSession, "The sessions are not matching")
        }

        var _ubDataTask: UBURLDataTask?
        var _collectedData: UBURLSessionDelegate.DataHolder?
        serialQueue.sync {
            _ubDataTask = tasks.object(forKey: dataTask)
            _collectedData = tasksData.object(forKey: dataTask)
        }

        guard let ubDataTask = _ubDataTask, ubDataTask.dataTask == dataTask, let dataHolder = _collectedData else {
            return
        }
        if dataHolder.data == nil {
            dataHolder.data = data
        } else {
            dataHolder.data!.append(data)
        }
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, dataTask _: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        urlSessionQueue.sync {
            assert(session == self._urlSession, "The sessions are not matching")
        }
        guard cachingLogic == nil else {
            // If we have a caching logic, we will skip the default caching implementation
            completionHandler(nil)
            return
        }

        completionHandler(proposedResponse)
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        urlSessionQueue.sync {
            assert(session == self._urlSession, "The sessions are not matching")
        }

        var _ubDataTask: UBURLDataTask?
        var _collectedData: UBURLSessionDelegate.DataHolder?
        serialQueue.sync {
            _ubDataTask = tasks.object(forKey: task)
            _collectedData = tasksData.object(forKey: task)
        }

        guard let ubDataTask = _ubDataTask, ubDataTask.dataTask == task, let dataHolder = _collectedData else {
            completionHandler(request)
            return
        }

        guard allowsRedirection else {
            completionHandler(nil)
            return
        }

        dataHolder.response = response
        dataHolder.request = request

        completionHandler(request)
    }

    /// Result of a `URLAuthenticationChallenge` evaluation.
    private typealias ChallengeEvaluation = (disposition: URLSession.AuthChallengeDisposition, credential: URLCredential?, error: Error?)

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        urlSessionQueue.sync {
            assert(session == self._urlSession, "The sessions are not matching")
        }

        var _ubDataTask: UBURLDataTask?
        var _collectedData: UBURLSessionDelegate.DataHolder?
        serialQueue.sync {
            _ubDataTask = tasks.object(forKey: task)
            _collectedData = tasksData.object(forKey: task)
        }

        guard let ubDataTask = _ubDataTask, ubDataTask.dataTask == task, let dataHolder = _collectedData else {
            return
        }

        let evaluation: ChallengeEvaluation =
            switch challenge.protectionSpace.authenticationMethod {
                case NSURLAuthenticationMethodServerTrust:
                    attemptServerTrustAuthentication(with: challenge)
                default:
                    (.performDefaultHandling, nil, nil)
            }

        if let error = evaluation.error {
            dataHolder.error = error
        }

        completionHandler(evaluation.disposition, evaluation.credential)
    }

    /// :nodoc:
    private func attemptServerTrustAuthentication(with challenge: URLAuthenticationChallenge) -> ChallengeEvaluation {
        let host = challenge.protectionSpace.host

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let trust = challenge.protectionSpace.serverTrust
        else {
            return (.performDefaultHandling, nil, nil)
        }

        do {
            guard let evaluator = serverTrustManager.serverTrustEvaluator(forHost: host) else {
                return (.performDefaultHandling, nil, nil)
            }

            try evaluator.evaluate(trust, forHost: host)

            return (.useCredential, URLCredential(trust: trust), nil)
        } catch {
            return (.cancelAuthenticationChallenge, nil, error)
        }
    }

    private func executeCachingLogic(cachingLogic: UBCachingLogic?, session: URLSession, task: URLSessionTask, ubDataTask: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?, error: Error?)
        -> CachedURLResponse?
    {
        guard let cachingLogic, let task = task as? URLSessionDataTask, let originalRequest = task.originalRequest else {
            return nil
        }

        let proposedResponse = cachingLogic.proposeCachedResponse(for: session, dataTask: task, ubDataTask: ubDataTask, request: request, response: response, data: data, metrics: metrics, error: error)

        if let proposedResponse {
            // If there is a proposed caching, cache it
            session.configuration.urlCache?.storeCachedResponse(proposedResponse, for: originalRequest)
        }

        return proposedResponse
    }
}

extension UBURLSessionDelegate {
    /// :nodoc:
    private class DataHolder {
        var cached: CachedURLResponse?
        /// :nodoc:
        var data: Data?
        /// :nodoc
        var request: URLRequest
        /// :nodoc:
        var response: URLResponse?
        /// :nodoc:
        var metrics: URLSessionTaskMetrics?
        /// :nodoc:
        var error: Error?
        /// :nodoc:
        init(_ request: URLRequest) {
            self.request = request
        }
    }
}
