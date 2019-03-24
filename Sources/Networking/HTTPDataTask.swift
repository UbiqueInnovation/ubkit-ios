//
//  HTTPDataTask.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

// - redirection
// - hooks for request changing
// - authentication: basic / OAUTH
// - check caching
// - Adapting and Retrying Requests
// - Error handling
// - Certificates
// - Network Reachability
// - CRON jobs

import Foundation

public final class HTTPDataTask {

    // MARK: - Properties

    private var session: URLSessionProtocol

    public var request: HTTPURLRequest {
        willSet {
            dataTask?.cancel()
        }
    }

    public var taskDescription: String? {
        willSet {
            dataTask?.taskDescription = newValue
        }
    }

    public var priority: Float {
        willSet {
            dataTask?.priority = newValue
        }
    }

    public var progressFractionComplete: Double {
        return dataTask?.progress.fractionCompleted ?? 0
    }

    private var dataTask: URLSessionDataTask? {
        willSet {
            dataTask?.cancel()
        }
    }

    private let workOperationQueue: OperationQueue

    private let callbackQueue: OperationQueue

    // MARK: - Initializers

    public init(request: HTTPURLRequest, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: URLSessionProtocol = URLSession.shared, callbackQueue: OperationQueue = .current ?? .main) {
        self.request = request
        self.session = session
        self.taskDescription = taskDescription
        self.priority = priority
        self.callbackQueue = callbackQueue
        state = .ready
        workOperationQueue = OperationQueue()
        workOperationQueue.name = "HTTPDataTask \(taskDescription ?? "<no description>")"
        workOperationQueue.qualityOfService = .userInitiated
        workOperationQueue.maxConcurrentOperationCount = 1
    }

    deinit {
        dataTask?.cancel()
    }

    // MARK: - Startin and stopping

    public func start() {
        workOperationQueue.addOperation { [weak self] in
            guard let self = self else {
                return
            }
            let dataTask = self.session.dataTask(with: self.request, completionHandler: { [weak self] data, response, error in
                self?.workOperationQueue.addOperation { [weak self] in
                    self?.dataTaskCompleted(data: data, response: response, error: error)
                }
            })
            self.dataTask = dataTask

            self.dataTaskProgressObservation = dataTask.progress.observe(\Progress.fractionCompleted, options: [.initial, .new], changeHandler: { [weak self] progress, _ in
                self?.notifyProgress(progress.fractionCompleted)
            })
            self.dataTaskStateObservation = dataTask.observe(\URLSessionDataTask.state, options: [.new], changeHandler: { [weak self] task, _ in
                switch task.state {
                case .running:
                    self?.state = .fetching
                default:
                    break
                }
            })
            dataTask.priority = self.priority
            dataTask.taskDescription = self.taskDescription
            self.state = .waitingExecution
            dataTask.resume()
        }
    }

    public func cancel() {
        dataTask?.cancel()
    }

    /// :nodoc:
    private func dataTaskCompleted(data: Data?, response: URLResponse?, error: Error?) {
        // Check for Task error
        guard error == nil else {
            if (error! as NSError).code == NSURLErrorCancelled {
                // The caller cancelled the request
                state = .cancelled
            } else {
                notifyCompletion(error: error!, response: nil)
            }
            return
        }

        // Check we have a HTTP Response
        guard let response = response as? HTTPURLResponse else {
            notifyCompletion(error: NetworkingError.notHTTPResponse, response: nil)
            return
        }

        state = .parsing

        // Validate the resonse
        do {
            try validate(response: response, data: data)
            notifyCompletion(data: data, response: response)
        } catch {
            notifyCompletion(error: error, response: response)
        }
    }

    // MARK: - State

    /// The state of the task
    public enum State: CustomDebugStringConvertible {
        /// Initial, the task is ready to start
        case ready
        /// The task is added and waiting for a spot to execute
        case waitingExecution
        /// The request is running
        case fetching
        /// Parsing the data
        case parsing
        /// The request finished
        case finished
        /// The operation was cancelled by the caller
        case cancelled

        /// :nodoc:
        public var debugDescription: String {
            switch self {
            case .ready:
                return "Initial"
            case .waitingExecution:
                return "Waiting Execution"
            case .fetching:
                return "Fetching"
            case .parsing:
                return "Parsing"
            case .finished:
                return "Finished"
            case .cancelled:
                return "Canceled"
            }
        }
    }

    /// Called when the state of the task changed. First parameter is the old state, the second parameter is the new state
    public typealias StateTransitionObservationBlock = (State, State) -> Void
    private var dataTaskStateObservation: NSKeyValueObservation?
    private var stateTransitionObservers: [StateTransitionObservationBlock] = []

    public private(set) var state: State {
        willSet {
            guard state != newValue else {
                return
            }
            // Validate state machine
            switch (state, newValue) {
            case (.ready, .waitingExecution), // Put the task in the queue
                 (.waitingExecution, .fetching), // Start task
                 (.waitingExecution, .cancelled), // Cancel task
                 (.fetching, .parsing), // Data received
                 (.fetching, .finished), // Error received
                 (.fetching, .cancelled), // Cancel task
                 (.parsing, .finished), // Data parsed
                 (.finished, .ready), // Reset task
                 (.cancelled, .ready): // Reset task
                break
            default:
                fatalError("Invalid state transition from \(state) -> \(newValue)")
            }
        }
        didSet {
            guard oldValue != state else {
                return
            }
            notifyStateTransition(old: oldValue, new: state)
        }
    }

    private func notifyStateTransition(old: State, new: State) {
        callbackQueue.addOperation { [weak self] in
            self?.stateTransitionObservers.forEach({ $0(old, new) })
        }
    }

    @discardableResult
    public func addStateTransitionObserver(_ observationBlock: @escaping StateTransitionObservationBlock) -> HTTPDataTask {
        stateTransitionObservers.append(observationBlock)
        return self
    }

    // MARK: Progress

    public typealias ProgressObservationBlock = (HTTPDataTask, Double) -> Void

    private var dataTaskProgressObservation: NSKeyValueObservation?
    private var progressObservers: [ProgressObservationBlock] = []

    private func notifyProgress(_ progress: Double) {
        callbackQueue.addOperation { [weak self] in
            guard let self = self else {
                return
            }
            self.progressObservers.forEach({ $0(self, progress) })
        }
    }

    @discardableResult
    public func addProgressObserver(_ observationBlock: @escaping ProgressObservationBlock) -> HTTPDataTask {
        progressObservers.append(observationBlock)
        return self
    }

    // MARK: - Completion

    public typealias CompletionObservationBlock<T> = (HTTPDataTaskResult<T>, HTTPURLResponse?) -> Void

    private var completionObservers: [CompletionBlockWrapper] = []

    private func notifyCompletion(error: Error, response: HTTPURLResponse?) {
        state = .finished
        callbackQueue.addOperation { [weak self] in
            self?.completionObservers.forEach({ $0.fail(error: error, response: response) })
        }
    }

    private func notifyCompletion(data: Data?, response: HTTPURLResponse) {
        state = .finished
        callbackQueue.addOperation { [weak self] in
            self?.completionObservers.forEach({ $0.parse(data: data, response: response) })
        }
    }

    @discardableResult
    public func addCompletionObserver(completionBlock: @escaping CompletionObservationBlock<Data>) -> HTTPDataTask {
        let wrapper = CompletionBlockWrapper(decoder: HTTPPassThroughDecoder(), completion: completionBlock)
        completionObservers.append(wrapper)
        return self
    }

    @discardableResult
    public func addCompletionObserver<T>(decoder: HTTPDataDecoder<T>, completionBlock: @escaping CompletionObservationBlock<T>) -> HTTPDataTask {
        let wrapper = CompletionBlockWrapper(decoder: decoder, completion: completionBlock)
        completionObservers.append(wrapper)
        return self
    }

    // MARK: - Validation

    private var responseValidators: [HTTPResponseValidator] = []

    private func validate(response: HTTPURLResponse, data: Data?) throws {
        try responseValidators.forEach({ try $0.validateHTTPResponse(response, data: data) })
    }

    @discardableResult
    public func addResponseValidator(_ validator: HTTPResponseValidator) -> HTTPDataTask {
        responseValidators.append(validator)
        return self
    }

    @discardableResult
    public func addResponseValidator(_ validationBlock: @escaping HTTPResponseValidatorBlock.ValidationBlock) -> HTTPDataTask {
        addResponseValidator(HTTPResponseValidatorBlock(validationBlock))
        return self
    }

    @discardableResult
    public func addResponseValidator(_ validators: [HTTPResponseValidator]) -> HTTPDataTask {
        responseValidators.append(contentsOf: validators)
        return self
    }
}

extension HTTPDataTask {
    private struct CompletionBlockWrapper {
        private let executionBlock: (Data?, HTTPURLResponse) -> Void
        private let failureBlock: (Error, HTTPURLResponse?) -> Void

        init(completion: @escaping CompletionObservationBlock<Data>) {
            executionBlock = { data, response in
                guard let data = data else {
                    completion(HTTPDataTaskResult.successEmptyBody, response)
                    return
                }
                completion(HTTPDataTaskResult.success(data), response)
            }

            failureBlock = { error, response in
                completion(HTTPDataTaskResult.failure(error), response)
            }
        }

        init<T>(decoder: HTTPDataDecoder<T>, completion: @escaping CompletionObservationBlock<T>) {
            executionBlock = { data, response in
                guard let data = data else {
                    completion(HTTPDataTaskResult.successEmptyBody, response)
                    return
                }
                do {
                    let decoded = try decoder.decode(data: data, response: response)
                    completion(HTTPDataTaskResult.success(decoded), response)
                } catch {
                    completion(HTTPDataTaskResult.failure(error), response)
                }
            }

            failureBlock = { error, response in
                completion(HTTPDataTaskResult.failure(error), response)
            }
        }

        func parse(data: Data?, response: HTTPURLResponse) {
            executionBlock(data, response)
        }

        func fail(error: Error, response: HTTPURLResponse?) {
            failureBlock(error, response)
        }
    }
}
