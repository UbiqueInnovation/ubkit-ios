//
//  UBURLDataTask.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// A data task that returns downloaded data directly to the app in memory.
public final class UBURLDataTask: UBURLSessionTask, CustomStringConvertible, CustomDebugStringConvertible {

    // MARK: - Properties

    /// The session used to create tasks
    public let session: DataTaskURLSession

    /// A queue for protecting the request
    private let requestQueue = DispatchQueue(label: "Request Queue")
    /// :nodoc:
    private var _request: UBURLRequest

    /// The request to execute. Setting this property will cancel any ongoing requests
    public var request: UBURLRequest {
        get {
            return requestQueue.sync {
                _request
            }
        }
        set {
            cancel()
            requestQueue.sync {
                _request = newValue
            }
        }
    }

    /// An app-provided description of the current task.
    public let taskDescription: String?

    /// The relative priority at which you’d like a host to handle the task, specified as a floating point value between 0.0 (lowest priority) and 1.0 (highest priority).
    public let priority: Float

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

    /// A queue for protecting the data task
    private let dataTaskQueue: DispatchQueue = DispatchQueue(label: "Data Task")
    private var _dataTask: URLSessionDataTask?
    /// The underlaying data task
    private var dataTask: URLSessionDataTask? {
        get {
            return dataTaskQueue.sync {
                _dataTask
            }
        }
        set {
            dataTaskQueue.sync {
                _dataTask = newValue
            }
        }
    }

    /// The callback queue where all callbacks take place
    private let callbackQueue: OperationQueue

    // MARK: - Initializers

    /// Initializes the data task.
    ///
    /// The task data can fetch resources online and execute requests. It offers alarge base of helpers and is built on top of `URLSession`.
    ///
    /// - Note: Only the default session will add the created task automatically to the global networking state tracking object. If you wish to use your own session object, don't forget to add it manually using the `Networking` APIs.
    ///
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - taskDescription: An app-provided description of the current task.
    ///   - priority: The relative priority at which you’d like a host to handle the task, specified as a floating point value between 0.0 (lowest priority) and 1.0 (highest priority).
    ///   - session: The session for the task creation
    ///   - callbackQueue: An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue. If none is provided then the callbacks are made on the main queue
    public init(request: UBURLRequest, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: DataTaskURLSession = UBURLSession.shared, callbackQueue: OperationQueue = .main) {
        _request = request
        self.session = session
        self.taskDescription = taskDescription
        self.priority = priority
        self.callbackQueue = callbackQueue
        progress = Progress(totalUnitCount: 0)
        _state = .initial

        progress.isCancellable = true
        progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
    }

    /// Initializes the data task.
    ///
    /// The task data can fetch resources online and execute requests. It offers alarge base of helpers and is built on top of `URLSession`.
    ///
    /// - Note: Only the default session will add the created task automatically to the global networking state tracking object. If you wish to use your own session object, don't forget to add it manually using the `Networking` APIs.
    ///
    /// - Parameters:
    ///   - url: A URL that represents the request to execute.
    ///   - taskDescription: An app-provided description of the current task.
    ///   - priority: The relative priority at which you’d like a host to handle the task, specified as a floating point value between 0.0 (lowest priority) and 1.0 (highest priority).
    ///   - session: The session for the task creation
    ///   - callbackQueue: An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue. If none is provided then the callbacks are made on the main queue
    public convenience init(url: URL, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: DataTaskURLSession = UBURLSession.shared, callbackQueue: OperationQueue = .main) {
        self.init(request: UBURLRequest(url: url), taskDescription: taskDescription, priority: priority, session: session, callbackQueue: callbackQueue)
    }

    /// :nodoc:
    deinit {
        dataTaskProgressObservation?.invalidate()
        dataTaskStateObservation?.invalidate()
        dataTask?.cancel()
    }

    // MARK: - Startin and stopping

    /// Start the task with the given request
    public func start() {
        // Cancel the previous task
        cancel()

        // Logging
        switch Networking.logger.logLevel {
        case .default:
            Networking.logger.debug("Starting task for \(description)")
        case .none:
            break
        case .verbose:
            Networking.logger.debug("Starting task for request \(debugDescription)")
        }

        // Set the state to waiting execution and launch the task
        state = .waitingExecution

        // Apply all modification
        requestModifier.modifyRequest(request) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case let .failure(error):
                self.attemptRecovery(data: nil, response: nil, error: error)
            case let .success(modifiedRequest):
                self.startRequest(request: modifiedRequest)
            }
        }
    }

    private func startRequest(request: UBURLRequest) {
        // Create a new task from the preferences
        let dataTask = session.dataTask(with: request, owner: self)

        // Set priority and description
        dataTask.priority = priority
        dataTask.taskDescription = taskDescription

        // Observe the task progress
        dataTaskProgressObservation = dataTask.observe(\.progress.fractionCompleted, options: [.initial, .new], changeHandler: { [weak self] task, _ in
            guard let self = self else {
                return
            }
            self.progress.totalUnitCount = task.progress.totalUnitCount
            self.progress.completedUnitCount = task.progress.completedUnitCount
            self.notifyProgress(self.progress.fractionCompleted)
        })

        // Observe the task state
        dataTaskStateObservation = dataTask.observe(\URLSessionDataTask.state, options: [.new], changeHandler: { [weak self] task, _ in
            switch task.state {
            case .running:
                if self?.state != .fetching {
                    self?.state = .fetching
                }
            default:
                break
            }
        })

        self.dataTask = dataTask
        dataTask.resume()
    }

    /// Cancel the current request
    public func cancel() {
        dataTaskProgressObservation?.invalidate()
        dataTaskStateObservation?.invalidate()
        requestModifier.cancelCurrentModification()
        failureRecoveryStrategy.cancelCurrentRecovery()
        if let dataTask = dataTask {
            Networking.logger.debug("Canceling task for \(description)")
            dataTask.cancel()
        }
    }

    /// Called when the corresponding network call has finished loading
    ///
    /// - Parameters:
    ///   - data: The data transfered
    ///   - response: The response received with the data
    ///   - error: The error in case of failure
    func dataTaskCompleted(data: Data?, response: HTTPURLResponse?, error: Error?, info: NetworkingTaskInfo?) {
        if let i = info, Networking.logger.logLevel == .verbose {
            Networking.logger.debug(i)
        }

        // Check for Task error
        guard error == nil else {
            if (error! as NSError).code == NSURLErrorCancelled {
                Networking.logger.debug("Task canceled: \(description)")
                // The caller cancelled the request
                state = .cancelled
                progress.completedUnitCount = 0
                progress.totalUnitCount = 0
            } else {
                attemptRecovery(data: data, response: response, error: error!)
            }
            return
        }

        guard let unwrappedResponse = response else {
            attemptRecovery(data: data, response: response, error: NetworkingError.notHTTPResponse)
            return
        }

        state = .parsing

        notifyCompletion(data: data, response: unwrappedResponse, info: info)
    }

    // MARK: - Request Modifier

    /// All the request modifiers
    private let requestModifier = UBURLRequestModifierGroup()
    /// Adds a request modifier.
    ///
    /// This modifier will be called everytime before the request is sent, and it gets a chance to modify the request.
    ///
    /// - Parameter modifier: The request modifier to add
    @discardableResult
    public func addRequestModifier(_ modifier: UBURLRequestModifier) -> Self {
        requestModifier.append(modifier)
        return self
    }

    // MARK: - State

    /// Called when the state of the task changed. First parameter is the old state, the second parameter is the new state
    public typealias StateTransitionObservationBlock = (State, State, UBURLDataTask) -> Void
    /// Holds the state observation
    private var dataTaskStateObservation: NSKeyValueObservation?
    /// :nodoc:
    private let stateTransitionObserversQueue = DispatchQueue(label: "State Observers")
    /// :nodoc:
    private var _stateTransitionObservers: [StateTransitionObservationBlock] = []
    /// Holds the state observers
    private var stateTransitionObservers: [StateTransitionObservationBlock] {
        return stateTransitionObserversQueue.sync {
            _stateTransitionObservers
        }
    }

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

    /// :nodoc:
    private let stateDispatchQueue = DispatchQueue(label: "State")
    /// :nodoc:
    private private(set) var _state: State {
        willSet {
            // Validate state machine
            switch (_state, newValue) {
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
                fatalError("Invalid state transition from \(_state) -> \(newValue)")
            }
        }
        didSet {
            notifyStateTransition(old: oldValue, new: _state)
        }
    }

    /// The current state of the task
    public private(set) var state: State {
        get {
            return stateDispatchQueue.sync {
                _state
            }
        }
        set {
            stateDispatchQueue.sync {
                _state = newValue
            }
        }
    }

    /// :nodoc:
    private func notifyStateTransition(old: State, new: State) {
        callbackQueue.addOperation { [weak self] in
            guard let self = self else {
                return
            }
            self.stateTransitionObservers.forEach({ $0(old, new, self) })
        }
    }

    /// Add an observer that gets called when the state changes. This observer will be called on the specified callback thread.
    ///
    /// - Parameter observationBlock: The block to execute when the state changes
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addStateTransitionObserver(_ observationBlock: @escaping StateTransitionObservationBlock) -> Self {
        stateDispatchQueue.sync {
            _stateTransitionObservers.append(observationBlock)
        }
        return self
    }

    // MARK: Progress

    /// A progress observation block. The second paramter is the percentage of completion, between 0.00 and 1.00
    public typealias ProgressObservationBlock = (UBURLDataTask, Double) -> Void
    /// The progress observation holder
    private var dataTaskProgressObservation: NSKeyValueObservation?
    /// :nodoc:
    private let progressObserversDispatchQueue = DispatchQueue(label: "Progress Observers")
    /// :nodoc:
    private var _progressObservers: [ProgressObservationBlock] = []
    /// The progress observers
    private var progressObservers: [ProgressObservationBlock] {
        return progressObserversDispatchQueue.sync {
            _progressObservers
        }
    }

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
        progressObserversDispatchQueue.sync {
            _progressObservers.append(observationBlock)
        }
        return self
    }

    // MARK: - Completion

    /// A completion handling block called at the end of the task.
    public typealias CompletionHandlingBlock<T> = (Result<T>, HTTPURLResponse?, NetworkingTaskInfo?, UBURLDataTask) -> Void
    /// A completion handling block called at the end of the task.
    public typealias CompletionHandlingNullableDataBlock = (Result<Data?>, HTTPURLResponse?, NetworkingTaskInfo?, UBURLDataTask) -> Void
    /// :nodoc:
    private let completionHandlersDispatchQueue = DispatchQueue(label: "Completion Handlers")
    /// :nodoc:
    private var _completionHandlers: [CompletionHandlerWrapper] = []
    /// The completion handlers
    private var completionHandlers: [CompletionHandlerWrapper] {
        return completionHandlersDispatchQueue.sync {
            _completionHandlers
        }
    }

    /// :nodoc:
    private func notifyCompletion(error: Error, response: HTTPURLResponse?, info: NetworkingTaskInfo?) {
        Networking.logger.debug("Task received error \(error) for \(description)")
        state = .finished
        callbackQueue.addOperation { [weak self] in
            guard let self = self else {
                return
            }
            self.completionHandlers.forEach({ $0.fail(error: error, response: response, info: info, caller: self) })
        }
    }

    /// :nodoc:
    private func notifyCompletion(data: Data?, response: HTTPURLResponse, info: NetworkingTaskInfo?) {
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

        state = .finished
        completionHandlers.forEach({ $0.parse(data: data, response: response, info: info, callbackQueue: self.callbackQueue, caller: self) })
    }

    /// Adds a completion handler that gets the raw data as is.
    ///
    /// - Parameter completionHandler: A completion handler
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addCompletionHandler(_ completionHandler: @escaping CompletionHandlingNullableDataBlock) -> Self {
        let wrapper = CompletionHandlerWrapper(completion: completionHandler)
        completionHandlersDispatchQueue.sync {
            _completionHandlers.append(wrapper)
        }
        return self
    }

    /// Adds a completion handler that gets the data decoded by the specified decoder.
    ///
    /// If no data is returned, there will be an error raised and the result will fail.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - completionHandler: A completion handler
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addCompletionHandler<T>(decoder: UBURLDataTaskDecoder<T>, completionHandler: @escaping CompletionHandlingBlock<T>) -> Self {
        let wrapper = CompletionHandlerWrapper(decoder: decoder, completion: completionHandler)
        completionHandlersDispatchQueue.sync {
            _completionHandlers.append(wrapper)
        }
        return self
    }

    // MARK: - Validation

    /// :nodoc:
    private let responseValidatorsDispatchQueue = DispatchQueue(label: "Response validators")
    /// :nodoc:
    private var _responseValidators: [HTTPURLResponseValidator] = []
    /// The validators
    private var responseValidators: [HTTPURLResponseValidator] {
        return responseValidatorsDispatchQueue.sync {
            _responseValidators
        }
    }

    /// :nodoc:
    func validate(response: HTTPURLResponse) throws {
        try responseValidators.forEach({ try $0.validateHTTPResponse(response) })
    }

    /// Adds a response validator.
    ///
    /// The response validator get's checked bafore any completion block is called right after the task receives the data.
    /// It can validate that the response or data are in order and can proceed for completion
    ///
    /// - Parameter validator: The validator
    /// - Returns: The data task for call chaining
    @discardableResult
    public func addResponseValidator(_ validator: HTTPURLResponseValidator) -> Self {
        responseValidatorsDispatchQueue.sync {
            _responseValidators.append(validator)
        }
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
    public func addResponseValidator(_ validators: [HTTPURLResponseValidator]) -> Self {
        responseValidatorsDispatchQueue.sync {
            _responseValidators.append(contentsOf: validators)
        }
        return self
    }

    // MARK: - Failure Recovery

    /// All the failure recovery strategies
    private let failureRecoveryStrategy = NetworkTaskRecoveryGroup()
    /// Adds a failure recovery strategy.
    ///
    /// This failure recovery strategy will be called everytime if the request has failed. The recovery is not called when the failure occurs on the decoding level. But only before the decoding stage, after the validation.
    ///
    /// - Parameter strategy: The failure recovery strategy to add
    @discardableResult
    public func addFailureRecoveryStrategy(_ strategy: NetworkingTaskRecoveryStrategy) -> Self {
        failureRecoveryStrategy.append(strategy)
        return self
    }

    /// :nodoc:
    private func attemptRecovery(data: Data?, response: HTTPURLResponse?, error: Error) {
        Networking.logger.debug("Attempting recovery of error \(error) for \(description)")
        failureRecoveryStrategy.recoverTask(self, data: data, response: response, error: error) { [weak self] result in
            switch result {
            case .cannotRecover:
                self?.notifyCompletion(error: error, response: response, info: nil)
            case let .recoveryOptions(options: options):
                self?.notifyCompletion(error: options, response: response, info: nil)
            case let .recovered(data: data, response: response, info: info):
                self?.notifyCompletion(data: data, response: response, info: info)
            case .restartDataTask:
                self?.start()
            }
        }
    }
}

extension UBURLDataTask {
    /// This is a wrapper that holds reference for a completion handler
    private struct CompletionHandlerWrapper {
        private let executionBlock: (Data?, HTTPURLResponse, NetworkingTaskInfo?, OperationQueue, UBURLDataTask) -> Void
        private let failureBlock: (Error, HTTPURLResponse?, NetworkingTaskInfo?, UBURLDataTask) -> Void

        /// :nodoc:
        init<T>(decoder: UBURLDataTaskDecoder<T>, completion: @escaping CompletionHandlingBlock<T>) {
            // Create the block that gets called when decoding is ready
            executionBlock = { data, response, info, callbackQueue, caller in
                guard let data = data else {
                    completion(.failure(NetworkingError.responseBodyIsEmpty), response, info, caller)
                    return
                }
                do {
                    let decoded = try decoder.decode(data: data, response: response)
                    callbackQueue.addOperation {
                        completion(.success(decoded), response, info, caller)
                    }
                } catch {
                    callbackQueue.addOperation {
                        completion(.failure(error), response, info, caller)
                    }
                }
            }

            // Create a block to be called on failure
            failureBlock = { error, response, info, caller in
                completion(.failure(error), response, info, caller)
            }
        }

        /// :nodoc:
        init(completion: @escaping CompletionHandlingNullableDataBlock) {
            // Create the block that gets called when success
            executionBlock = { data, response, info, callbackQueue, caller in
                callbackQueue.addOperation {
                    completion(.success(data), response, info, caller)
                }
            }
            // Create a block to be called on failure
            failureBlock = { error, response, info, caller in
                completion(.failure(error), response, info, caller)
            }
        }

        /// :nodoc:
        func parse(data: Data?, response: HTTPURLResponse, info: NetworkingTaskInfo?, callbackQueue: OperationQueue, caller: UBURLDataTask) {
            executionBlock(data, response, info, callbackQueue, caller)
        }

        /// :nodoc:
        func fail(error: Error, response: HTTPURLResponse?, info: NetworkingTaskInfo?, caller: UBURLDataTask) {
            failureBlock(error, response, info, caller)
        }
    }
}
