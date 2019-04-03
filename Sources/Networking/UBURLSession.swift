//
//  UBURLSession.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

private class Manager: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    /// Storage of the task mapping
    let tasks = NSMapTable<URLSessionTask, UBURLDataTask>(keyOptions: .weakMemory, valueOptions: .weakMemory)
    /// Storage of the task data
    private let tasksData = NSMapTable<URLSessionTask, DataHolder>(keyOptions: .weakMemory, valueOptions: .strongMemory)

    weak var urlSession: URLSession?

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
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
            ubDataTask.dataTaskCompleted(data: nil, response: nil, error: error)
            return
        }

        let ubResponse: UBHTTPURLResponse?
        if let r = collectedData.response as? HTTPURLResponse {
            ubResponse = UBHTTPURLResponse(response: r, metrics: collectedData.metrics)
        } else {
            ubResponse = nil
        }

        ubDataTask.dataTaskCompleted(data: collectedData.data, response: ubResponse, error: error)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        assert(session == urlSession, "The sessions are not matching")
        guard let dataHolder = tasksData.object(forKey: task) else {
            return
        }
        dataHolder.metrics = metrics
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
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
            dataHolder = DataHolder(response)
            tasksData.setObject(dataHolder, forKey: dataTask)
        }

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

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
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

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        assert(session == urlSession, "The sessions are not matching")
        // TODO:
        print(proposedResponse)
        print(dataTask)
        completionHandler(nil)
    }
}

public class UBURLSession: DataTaskURLSession {
    public static let shared: UBURLSession = {
        let queue = OperationQueue()
        queue.name = "UBURLSession Shared"
        queue.qualityOfService = .userInitiated
        var configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        configuration.networkServiceType = .responsiveData
        return UBURLSession(configuration: configuration, delegateQueue: OperationQueue())
    }()

    /// The underlaying session
    private let urlSession: URLSession

    private let manager: Manager = Manager()

    // MARK: - Creating a Session

    /// Creates a session with the specified session configuration, delegate, and operation queue.
    ///
    /// - Parameters:
    ///   - configuration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, and credential storage.
    ///   - delegate: A session delegate object that handles requests for authentication and other session-related events.
    ///   - queue: An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue, in order to ensure the correct ordering of callbacks. If nil, the session creates a serial operation queue for performing all delegate method calls and completion handler calls.
    public init(configuration: URLSessionConfiguration, delegateQueue queue: OperationQueue?) {
        urlSession = URLSession(configuration: configuration, delegate: manager, delegateQueue: queue)
        manager.urlSession = urlSession
    }

    deinit {
        invalidateAndCancel()
    }

    /// :nodoc:
    public func dataTask(with request: UBURLRequest, owner: UBURLDataTask) -> URLSessionDataTask {
        let sessionDataTask = urlSession.dataTask(with: request.getRequest())
        manager.tasks.setObject(owner, forKey: sessionDataTask)
        return sessionDataTask
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

private class DataHolder {
    var data: Data?
    var response: URLResponse
    var metrics: URLSessionTaskMetrics?
    var error: Error?
    init(_ response: URLResponse) {
        self.response = response
    }
}
