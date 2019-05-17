//
//  UBURLSession+Delegate.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

/// An object defining methods that URL session instances call to handle task-level events.
class UBURLSessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    /// Storage of the task mapping
    private let tasks = NSMapTable<URLSessionTask, UBURLDataTask>(keyOptions: .weakMemory, valueOptions: .weakMemory)
    /// Storage of the task data
    private let tasksData = NSMapTable<URLSessionTask, DataHolder>(keyOptions: .weakMemory, valueOptions: .strongMemory)

    /// The url session, for verification purpouses
    weak var urlSession: URLSession?

    /// The manager providing server trust verification
    private let serverTrustManager: ServerTrustManager

    /// :nodoc:
    private let allowsRedirection: Bool

    /// :nodoc:
    let cachingLogic: CachingLogic?

    /// Initializes the delegate with a configuration
    ///
    /// - Parameter configuration: The configuration to use
    init(configuration: UBURLSessionConfiguration) {
        serverTrustManager = ServerTrustManager(evaluators: configuration.hostsServerTrusts, default: configuration.defaultServerTrust)
        allowsRedirection = configuration.allowRedirections
        cachingLogic = configuration.cachingLogic
        super.init()
    }

    /// Adds a task pair to the list of monitored tasks.
    func addTaskPair(key: URLSessionTask, value: UBURLDataTask, cachedResponse: CachedURLResponse?) {
        tasks.setObject(value, forKey: key)
        let dataHolder = DataHolder(key.originalRequest!)
        dataHolder.cached = cachedResponse
        tasksData.setObject(dataHolder, forKey: key)
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        assert(session == urlSession, "The sessions are not matching")
        defer {
            // Clear the collected data
            tasksData.removeObject(forKey: task)
            tasks.removeObject(forKey: task)
        }

        guard let ubDataTask = tasks.object(forKey: task) else {
            assertionFailure("Should have a data holder")
            return
        }

        guard let collectedData = tasksData.object(forKey: task) else {
            ubDataTask.dataTaskCompleted(data: nil, response: nil, error: error, info: nil)
            return
        }

        // Execute the caching logic
        executeCachingLogic(cachingLogic: cachingLogic, session: session, task: task, ubDataTask: ubDataTask, request: collectedData.request, response: collectedData.response, data: collectedData.data, metrics: collectedData.metrics)

        guard let response = collectedData.response as? HTTPURLResponse else {
            ubDataTask.dataTaskCompleted(data: collectedData.data, response: nil, error: error, info: NetworkingTaskInfo(metrics: collectedData.metrics, cacheHit: false))
            return
        }

        // If not modified return the cached data
        if response.statusCode == StandardHTTPCode.notModified, let cached = collectedData.cached {
            ubDataTask.dataTaskCompleted(data: cached.data, response: cached.response as? HTTPURLResponse, error: collectedData.error ?? error, info: NetworkingTaskInfo(metrics: collectedData.metrics, cacheHit: true))
            return
        }

        ubDataTask.dataTaskCompleted(data: collectedData.data, response: response, error: collectedData.error ?? error, info: NetworkingTaskInfo(metrics: collectedData.metrics, cacheHit: false))
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        assert(session == urlSession, "The sessions are not matching")
        guard let dataHolder = tasksData.object(forKey: task) else {
            assertionFailure("Should have a data holder")
            return
        }
        dataHolder.metrics = metrics
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        assert(session == urlSession, "The sessions are not matching")

        guard let ubDataTask = tasks.object(forKey: dataTask), let dataHolder = tasksData.object(forKey: dataTask) else {
            assertionFailure("Should have a data holder")
            completionHandler(.cancel)
            return
        }

        dataHolder.response = response

        guard let httpRespnse = response as? HTTPURLResponse else {
            dataHolder.error = NetworkingError.notHTTPResponse
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
        assert(session == urlSession, "The sessions are not matching")
        guard let dataHolder = tasksData.object(forKey: dataTask) else {
            assertionFailure("Should have a data holder")
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
        assert(session == urlSession, "The sessions are not matching")
        guard cachingLogic == nil else {
            // If we have a caching logic, we will skip the default caching implementation
            completionHandler(nil)
            return
        }

        completionHandler(proposedResponse)
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        assert(session == urlSession, "The sessions are not matching")
        guard allowsRedirection else {
            completionHandler(nil)
            return
        }
        guard let dataHolder = tasksData.object(forKey: task) else {
            assertionFailure("Should have a data holder")
            completionHandler(request)
            return
        }
        assert(response == dataHolder.response)
        dataHolder.request = request
        completionHandler(request)
    }

    /// Result of a `URLAuthenticationChallenge` evaluation.
    private typealias ChallengeEvaluation = (disposition: URLSession.AuthChallengeDisposition, credential: URLCredential?, error: Error?)

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        assert(session == urlSession, "The sessions are not matching")

        guard let dataHolder = tasksData.object(forKey: task) else {
            return
        }

        let evaluation: ChallengeEvaluation

        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            evaluation = attemptServerTrustAuthentication(with: challenge)
        default:
            evaluation = (.performDefaultHandling, nil, nil)
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
            let trust = challenge.protectionSpace.serverTrust else {
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

    private func executeCachingLogic(cachingLogic: CachingLogic?, session: URLSession, task: URLSessionTask, ubDataTask: UBURLDataTask, request: URLRequest, response: URLResponse?, data: Data?, metrics: URLSessionTaskMetrics?) {
        guard let cachingLogic = cachingLogic, let task = task as? URLSessionDataTask, let response = response as? HTTPURLResponse, let originalRequest = task.originalRequest else {
            return
        }

        let proposedResponse = cachingLogic.proposeCachedResponse(for: session, dataTask: task, ubDataTask: ubDataTask, request: request, response: response, data: data, metrics: metrics)

        if let proposedResponse = proposedResponse {
            session.configuration.urlCache?.storeCachedResponse(proposedResponse, for: originalRequest)
        }
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
