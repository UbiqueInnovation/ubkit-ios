//
//  HTTPDataTask.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

// - Move to Dispatch queue
// - check caching
// - redirection
// - Create wrapping session
// - Certificate pinning
// - hooks for request changing
// - authentication: basic / OAUTH
// - Adapting and Retrying Requests
// - Error handling
// - Network Reachability
// - CRON jobs

import Foundation

/// A data task that returns downloaded data directly to the app in memory.
public final class HTTPDataTask: CustomStringConvertible, CustomDebugStringConvertible {

    // MARK: - Properties

    /// The session used to create tasks
    public var session: URLSessionProtocol {
        willSet {
            dataTask?.cancel()
        }
    }

    /// The request to execute. Setting this property will cancel any ongoing requests
    public var request: HTTPURLRequest {
        willSet {
            dataTask?.cancel()
        }
    }

    /// An app-provided description of the current task.
    public var taskDescription: String? {
        willSet {
            dataTask?.taskDescription = newValue
        }
    }

    /// The relative priority at which you’d like a host to handle the task, specified as a floating point value between 0.0 (lowest priority) and 1.0 (highest priority).
    public var priority: Float {
        willSet {
            dataTask?.priority = newValue
        }
    }

    /// :nodoc:
    public var description: String {
        return taskDescription ?? request.description
    }

    /// :nodoc:
    public var debugDescription: String {
        return request.debugDescription
    }

    /// A representation of the overall task progress.
    public let progress: Progress

    /// The underlaying data task
    private var dataTask: URLSessionDataTask?

    /// A queue for parsing and validating data
    private let underlyingQueue: OperationQueue

    /// The callback queue where all callbacks take place
    private let callbackQueue: OperationQueue

    // MARK: - Initializers

    /// Initializes the data task.
    ///
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - taskDescription: An app-provided description of the current task.
    ///   - priority: The relative priority at which you’d like a host to handle the task, specified as a floating point value between 0.0 (lowest priority) and 1.0 (highest priority).
    ///   - session: The session for the task creation
    ///   - callbackQueue: An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue. If none is provided then the callbacks are made on the main queue
    public init(request: HTTPURLRequest, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: URLSessionProtocol = URLSession.shared, callbackQueue: OperationQueue = .main) {
        self.request = request
        self.session = session
        self.taskDescription = taskDescription
        self.priority = priority
        self.callbackQueue = callbackQueue
        progress = Progress(totalUnitCount: 0)
        state = .initial

        underlyingQueue = OperationQueue()
        underlyingQueue.name = "HTTPDataTask \(taskDescription ?? "<no description>")"
        underlyingQueue.qualityOfService = .userInitiated
        underlyingQueue.maxConcurrentOperationCount = 1

        progress.isCancellable = true
        progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
    }

    /// :nodoc:
    deinit {
        dataTask?.cancel()
        underlyingQueue.cancelAllOperations()
        callbackQueue.cancelAllOperations()
    }

    // MARK: - Startin and stopping

    /// Start the task with the given request
    public func start() {
        // Synchronize the start to avoid internal state conflicts
        underlyingQueue.addOperation { [weak self] in
            guard let self = self else {
                return
            }

            switch Networking.logger.logLevel {
            case .default:
                Networking.logger.debug("Starting task for \(self.description)")
            case .none:
                break
            case .verbose:
                Networking.logger.debug("Starting task for request \(self.debugDescription)")
            }

            // Cancel the previous task
            self.dataTask?.cancel()

            // Create a new task from the preferences
            let dataTask = self.session.dataTask(with: self.request, completionHandler: { [weak self] data, response, error in
                self?.underlyingQueue.addOperation { [weak self] in
                    self?.dataTaskCompleted(data: data, response: response, error: error)
                }
            })

            // Assign the new created task
            self.dataTask = dataTask

            // Observe the task progress
            self.dataTaskProgressObservation = dataTask.progress.observe(\Progress.fractionCompleted, options: [.initial, .new], changeHandler: { [weak self] progress, _ in
                guard let self = self else {
                    return
                }
                self.progress.totalUnitCount = progress.totalUnitCount
                self.progress.completedUnitCount = progress.completedUnitCount
                self.notifyProgress(self.progress.fractionCompleted)
            })

            // Observe the task state
            self.dataTaskStateObservation = dataTask.observe(\URLSessionDataTask.state, options: [.new], changeHandler: { [weak self] task, _ in
                switch task.state {
                case .running:
                    self?.state = .fetching
                default:
                    break
                }
            })

            // Set priority and description
            dataTask.priority = self.priority
            dataTask.taskDescription = self.taskDescription

            // Set the state to waiting execution and launch the task
            self.state = .waitingExecution
            dataTask.resume()
        }
    }

    /// Cancel the current request
    public func cancel() {
        underlyingQueue.addOperation { [weak self] in
            Networking.logger.debug("Canceling task for \(self?.description ?? "-")")
            self?.dataTask?.cancel()
        }
    }

    /// :nodoc:
    private func dataTaskCompleted(data: Data?, response: URLResponse?, error: Error?) {
        // Check for Task error
        guard error == nil else {
            if (error! as NSError).code == NSURLErrorCancelled {
                Networking.logger.debug("Task canceled: \(description)")
                // The caller cancelled the request
                state = .cancelled
                progress.completedUnitCount = 0
                progress.totalUnitCount = 0
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

    /// Called when the state of the task changed. First parameter is the old state, the second parameter is the new state
    public typealias StateTransitionObservationBlock = (State, State) -> Void
    /// Holds the state observation
    private var dataTaskStateObservation: NSKeyValueObservation?
    /// Holds the state observers
    private var stateTransitionObservers: [StateTransitionObservationBlock] = []

    /// The state of the task
    public enum State: CustomDebugStringConvertible {
        /// Initial, the task was never run
        case initial
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
            case .initial:
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

    /// The current state of the task
    public private(set) var state: State {
        willSet {
            // Validate state machine
            switch (state, newValue) {
            case (.initial, .waitingExecution), // Put the task in the queue
                 (.waitingExecution, .fetching), // Start task
                 (.waitingExecution, .cancelled), // Cancel task
                 (.fetching, .parsing), // Data received
                 (.fetching, .finished), // Error received
                 (.fetching, .cancelled), // Cancel task
                 (.parsing, .finished), // Data parsed
                 (.finished, .waitingExecution), // Restart task
                 (.cancelled, .waitingExecution): // Restart task
                break
            default:
                fatalError("Invalid state transition from \(state) -> \(newValue)")
            }
        }
        didSet {
            notifyStateTransition(old: oldValue, new: state)
        }
    }

    /// :nodoc:
    private func notifyStateTransition(old: State, new: State) {
        callbackQueue.addOperation { [weak self] in
            self?.stateTransitionObservers.forEach({ $0(old, new) })
        }
    }

    /// Add an observer that gets called when the state changes. This observer will be called on the specified callback thread.
    ///
    /// - Parameter observationBlock: The block to execute when the state changes
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addStateTransitionObserver(_ observationBlock: @escaping StateTransitionObservationBlock) -> Self {
        stateTransitionObservers.append(observationBlock)
        return self
    }

    // MARK: Progress

    /// A progress observation block. The second paramter is the percentage of completion, between 0.00 and 1.00
    public typealias ProgressObservationBlock = (HTTPDataTask, Double) -> Void
    /// The progress observation holder
    private var dataTaskProgressObservation: NSKeyValueObservation?
    /// The progress observers
    private var progressObservers: [ProgressObservationBlock] = []

    /// :nodoc:
    private func notifyProgress(_ progress: Double) {
        callbackQueue.addOperation { [weak self] in
            guard let self = self else {
                return
            }
            self.progressObservers.forEach({ $0(self, progress) })
        }
    }

    /// Adds an observer block that gets called everytime the progress changes
    ///
    /// - Parameter observationBlock: The observer block
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addProgressObserver(_ observationBlock: @escaping ProgressObservationBlock) -> Self {
        progressObservers.append(observationBlock)
        return self
    }

    // MARK: - Completion

    /// A completion handling block called at the end of the task.
    public typealias CompletionHandlingBlock<T> = (HTTPDataTaskResult<T>, HTTPURLResponse?) -> Void
    /// The completion handlers
    private var completionHandlers: [CompletionHandlerWrapper] = []

    /// :nodoc:
    private func notifyCompletion(error: Error, response: HTTPURLResponse?) {
        Networking.logger.debug("Task received error \(error) for \(description)")
        state = .finished
        callbackQueue.addOperation { [weak self] in
            self?.completionHandlers.forEach({ $0.fail(error: error, response: response) })
        }
    }

    /// :nodoc:
    private func notifyCompletion(data: Data?, response: HTTPURLResponse) {
        state = .finished

        // Do some logging
        switch Networking.logger.logLevel {
        case .verbose:
            if let data = data {
                Networking.logger.debug("Task completed for \(response.debugDescription)\nBody: \(String(data: data, encoding: .utf8) ?? "<Unparsable to UTF-8>")")
            } else {
                Networking.logger.debug("Task completed with empty body for \(response.debugDescription)")
            }
        case .default:
            Networking.logger.debug("Task completed for \(description)")
        default:
            break
        }

        completionHandlers.forEach({ $0.parse(data: data, response: response, callbackQueue: callbackQueue) })
    }

    /// Adds a completion handler that gets the raw data as is.
    ///
    /// - Parameter completionHandler: A completion handler
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addCompletionHandler(_ completionHandler: @escaping CompletionHandlingBlock<Data>) -> Self {
        let wrapper = CompletionHandlerWrapper(decoder: HTTPPassThroughDecoder(), completion: completionHandler)
        completionHandlers.append(wrapper)
        return self
    }

    /// Adds a completion handler that gets the data decoded by the specified decoder.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - completionHandler: A completion handler
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addCompletionHandler<T>(decoder: HTTPDataDecoder<T>, completionHandler: @escaping CompletionHandlingBlock<T>) -> Self {
        let wrapper = CompletionHandlerWrapper(decoder: decoder, completion: completionHandler)
        completionHandlers.append(wrapper)
        return self
    }

    // MARK: - Validation

    /// The validators
    private var responseValidators: [HTTPResponseValidator] = []

    /// :nodoc:
    private func validate(response: HTTPURLResponse, data: Data?) throws {
        Networking.logger.debug("Validating response for \(description)")
        try responseValidators.forEach({ try $0.validateHTTPResponse(response, data: data) })
    }

    /// Adds a response validator.
    ///
    /// The response validator get's checked bafore any completion block is called right after the task receives the data.
    /// It can validate that the response or data are in order and can proceed for completion
    ///
    /// - Parameter validator: The validator
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addResponseValidator(_ validator: HTTPResponseValidator) -> Self {
        responseValidators.append(validator)
        return self
    }

    /// Adds a response validator block.
    ///
    /// The response validator get's checked bafore any completion block is called right after the task receives the data.
    /// It can validate that the response or data are in order and can proceed for completion
    ///
    /// - Parameter validationBlock: The validator block
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addResponseValidator(_ validationBlock: @escaping HTTPResponseValidatorBlock.ValidationBlock) -> Self {
        addResponseValidator(HTTPResponseValidatorBlock(validationBlock))
        return self
    }

    /// Adds response validators.
    ///
    /// The response validator get's checked bafore any completion block is called right after the task receives the data.
    /// It can validate that the response or data are in order and can proceed for completion
    ///
    /// - Parameter validators: An array of validators
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addResponseValidator(_ validators: [HTTPResponseValidator]) -> Self {
        responseValidators.append(contentsOf: validators)
        return self
    }
}

extension HTTPDataTask {
    /// This is a wrapper that holds reference for a completion handler
    private struct CompletionHandlerWrapper {
        private let executionBlock: (Data?, HTTPURLResponse, OperationQueue) -> Void
        private let failureBlock: (Error, HTTPURLResponse?) -> Void

        /// :nodoc:
        init<T>(decoder: HTTPDataDecoder<T>, completion: @escaping CompletionHandlingBlock<T>) {
            // Create the block that gets called when decoding is ready
            executionBlock = { data, response, callbackQueue in
                guard let data = data else {
                    completion(HTTPDataTaskResult.successEmptyBody, response)
                    return
                }
                do {
                    let decoded = try decoder.decode(data: data, response: response)
                    callbackQueue.addOperation {
                        completion(HTTPDataTaskResult.success(decoded), response)
                    }
                } catch {
                    callbackQueue.addOperation {
                        completion(HTTPDataTaskResult.failure(error), response)
                    }
                }
            }

            // Create a block to be called on failure
            failureBlock = { error, response in
                completion(HTTPDataTaskResult.failure(error), response)
            }
        }

        /// :nodoc:
        func parse(data: Data?, response: HTTPURLResponse, callbackQueue: OperationQueue) {
            executionBlock(data, response, callbackQueue)
        }

        /// :nodoc:
        func fail(error: Error, response: HTTPURLResponse?) {
            failureBlock(error, response)
        }
    }
}
