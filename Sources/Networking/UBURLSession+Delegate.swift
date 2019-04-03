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

    /// Initializes the delegate with a configuration
    ///
    /// - Parameter configuration: The configuration to use
    init(configuration: UBURLSessionConfiguration) {
        serverTrustManager = ServerTrustManager(evaluators: configuration.hostsServerTrusts, default: configuration.defaultServerTrust)
        super.init()
    }

    /// Adds a task pair to the list of monitored tasks.
    func addTaskPair(key: URLSessionTask, value: UBURLDataTask) {
        tasks.setObject(value, forKey: key)
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
            return
        }

        guard let collectedData = tasksData.object(forKey: task) else {
            ubDataTask.dataTaskCompleted(data: nil, response: nil, error: error, info: nil)
            return
        }

        ubDataTask.dataTaskCompleted(data: collectedData.data, response: collectedData.response as? HTTPURLResponse, error: collectedData.error ?? error, info: NetworkingTaskInfo(metrics: collectedData.metrics))
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        assert(session == urlSession, "The sessions are not matching")
        guard let dataHolder = tasksData.object(forKey: task) else {
            let dh = DataHolder()
            dh.metrics = metrics
            tasksData.setObject(dh, forKey: task)
            return
        }
        dataHolder.metrics = metrics
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        assert(session == urlSession, "The sessions are not matching")

        guard let ubDataTask = tasks.object(forKey: dataTask) else {
            tasksData.removeObject(forKey: dataTask)
            completionHandler(.cancel)
            return
        }

        let dataHolder: DataHolder
        if let dh = tasksData.object(forKey: dataTask) {
            dataHolder = dh
        } else {
            dataHolder = DataHolder()
            tasksData.setObject(dataHolder, forKey: dataTask)
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
            assertionFailure("We received data without receiving a response")
            return
        }
        if dataHolder.data == nil {
            dataHolder.data = data
        } else {
            dataHolder.data!.append(data)
        }
    }

    /// :nodoc:
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        assert(session == urlSession, "The sessions are not matching")
        // TODO:
        print(proposedResponse)
        print(dataTask)
        completionHandler(nil)
    }

    /// Result of a `URLAuthenticationChallenge` evaluation.
    private typealias ChallengeEvaluation = (disposition: URLSession.AuthChallengeDisposition, credential: URLCredential?, error: Error?)

    /// :nodoc:
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        assert(session == urlSession, "The sessions are not matching")

        let dataHolder: DataHolder
        if let dh = tasksData.object(forKey: task) {
            dataHolder = dh
        } else {
            dataHolder = DataHolder()
            tasksData.setObject(dataHolder, forKey: task)
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
}

extension UBURLSessionDelegate {
    /// :nodoc:
    private class DataHolder {
        /// :nodoc:
        var data: Data?
        /// :nodoc:
        var response: URLResponse?
        /// :nodoc:
        var metrics: URLSessionTaskMetrics!
        /// :nodoc:
        var error: Error?
    }
}
