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
    public let session: UBDataTaskURLSession

    /// The request to execute.
    public let request: UBURLRequest

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

    /// The underlaying data task
    private var dataTask: URLSessionDataTask?

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
    public init(request: UBURLRequest, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: UBDataTaskURLSession = Networking.sharedSession, callbackQueue: OperationQueue = .main) {
        self.request = request
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
        // Add the created task to the global network activity
        Networking.addToGlobalNetworkActivity(self)
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
    public convenience init(url: URL, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: UBDataTaskURLSession = Networking.sharedSession, callbackQueue: OperationQueue = .main) {
        self.init(request: UBURLRequest(url: url), taskDescription: taskDescription, priority: priority, session: session, callbackQueue: callbackQueue)
    }

    /// :nodoc:
    deinit {
        dataTaskProgressObservation?.invalidate()
        dataTaskProgressObservation = nil
        dataTaskStateObservation?.invalidate()
        dataTaskStateObservation = nil
        dataTask?.cancel()
        requestStartSemaphore.signal()
    }

    // MARK: - Startin and stopping

    // The semaphore ensuring no two threads can call start simultaniously
    private let requestStartSemaphore = DispatchSemaphore(value: 1)

    /// Start the task with the given request. It will cancel any ongoing request
    public func start() {
        // Wait for any ongoing request start
        requestStartSemaphore.wait()

        // Cancel the previous task
        cancel()

        // Set the state to waiting execution and launch the task
        state = .waitingExecution

        // Apply all modification
        requestModifier.modifyRequest(request) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case let .failure(error):
                self.requestStartSemaphore.signal()
                self.attemptRecovery(data: nil, response: nil, error: error)
            case let .success(modifiedRequest):
                // Create a new task from the preferences
                guard let dataTask = self.session.dataTask(with: modifiedRequest, owner: self) else {
                    if self.state == .cancelled {
                        self.state = .finished
                    }
                    return
                }

                // Set priority and description
                dataTask.priority = self.priority
                dataTask.taskDescription = self.taskDescription

                // Observe the task progress
                self.dataTaskProgressObservation = dataTask.observe(\.progress.fractionCompleted, options: [.initial, .new], changeHandler: { [weak self] task, _ in
                    guard let self = self else {
                        return
                    }
                    self.progress.totalUnitCount = task.progress.totalUnitCount
                    self.progress.completedUnitCount = task.progress.completedUnitCount
                    self.notifyProgress(self.progress.fractionCompleted)
                })

                // Observe the task state
                self.dataTaskStateObservation = dataTask.observe(\URLSessionDataTask.state, options: [.new], changeHandler: { [weak self] task, _ in
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
                self.requestStartSemaphore.signal()
                dataTask.resume()
            }
        }
    }

    /// Cancel the current request
    public func cancel() {
        dataTaskProgressObservation = nil
        dataTaskStateObservation = nil
        requestModifier.cancelCurrentModification()
        failureRecoveryStrategy.cancelCurrentRecovery()
        dataTask?.cancel()
        switch state {
        case .initial, .parsing, .finished, .cancelled:
            break
        case .fetching, .waitingExecution:
            state = .cancelled
        }
    }

    /// Called when the corresponding network call has finished loading
    ///
    /// - Parameters:
    ///   - data: The data transfered
    ///   - response: The response received with the data
    ///   - error: The error in case of failure
    func dataTaskCompleted(data: Data?, response: HTTPURLResponse?, error: Error?, info: UBNetworkingTaskInfo?) {
        // Check for Task error
        guard error == nil else {
            if (error! as NSError).code == NSURLErrorCancelled {
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
            attemptRecovery(data: data, response: response, error: UBNetworkingError.notHTTPResponse)
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
    public func addRequestModifier(_ modifier: UBURLRequestModifier) {
        requestModifier.append(modifier)
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
    private var _state: State {
        willSet {
            // Validate state machine
            switch (_state, newValue) {
            case (.initial, .waitingExecution), // Put the task in the queue
                 (.waitingExecution, .fetching), // Start task
                 (.waitingExecution, .cancelled), // Cancel task
                 (.waitingExecution, .parsing), // Returned from cache
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
            self.stateTransitionObservers.forEach { $0(old, new, self) }
        }
    }

    /// Add an observer that gets called when the state changes. This observer will be called on the specified callback thread.
    ///
    /// - Parameter observationBlock: The block to execute when the state changes
    public func addStateTransitionObserver(_ observationBlock: @escaping StateTransitionObservationBlock) {
        stateTransitionObserversQueue.sync {
            _stateTransitionObservers.append(observationBlock)
        }
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
            self.progressObservers.forEach { $0(self, progress) }
        }
    }

    /// Adds an observer block that gets called everytime the progress changes
    ///
    /// - Parameter observationBlock: The observer block
    public func addProgressObserver(_ observationBlock: @escaping ProgressObservationBlock) {
        progressObserversDispatchQueue.sync {
            _progressObservers.append(observationBlock)
        }
    }

    // MARK: - Completion

    /// A completion handling block called at the end of the task.
    public typealias CompletionHandlingBlock<T> = (Result<T, Error>, HTTPURLResponse?, UBNetworkingTaskInfo?, UBURLDataTask) -> Void
    /// A completion handling block called at the end of the task.
    public typealias CompletionHandlingNullableDataBlock = (Result<Data?, Error>, HTTPURLResponse?, UBNetworkingTaskInfo?, UBURLDataTask) -> Void
    /// :nodoc:
    private let completionHandlersDispatchQueue = DispatchQueue(label: "Completion Handlers")
    /// The completion handlers
    private var _completionHandlers: [CompletionHandlerWrapper] = []

    private var completionHandlers: [CompletionHandlerWrapper] {
        return completionHandlersDispatchQueue.sync {
            _completionHandlers
        }
    }

    /// :nodoc:
    private func notifyCompletion(error: Error, response: HTTPURLResponse?, info: UBNetworkingTaskInfo?) {
        state = .finished
        completionHandlers.forEach { $0.fail(error: error, response: response, info: info, callbackQueue: callbackQueue, caller: self) }
    }

    /// :nodoc:
    private func notifyCompletion(data: Data?, response: HTTPURLResponse, info: UBNetworkingTaskInfo?) {
        state = .finished
        completionHandlers.forEach { $0.parse(data: data, response: response, info: info, callbackQueue: self.callbackQueue, caller: self) }
    }

    /// Adds a completion handler that gets the raw data as is.
    ///
    /// - Parameter completionHandler: A completion handler
    public func addCompletionHandler(_ completionHandler: @escaping CompletionHandlingNullableDataBlock) {
        let wrapper = CompletionHandlerWrapper(completion: completionHandler)
        completionHandlersDispatchQueue.sync {
            _completionHandlers.append(wrapper)
        }
    }

    /// Adds a completion handler that gets the data decoded by the specified decoder.
    ///
    /// If no data is returned, there will be an error raised and the result will fail.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - completionHandler: A completion handler
    public func addCompletionHandler<T>(decoder: UBURLDataTaskDecoder<T>, completionHandler: @escaping CompletionHandlingBlock<T>) {
        let wrapper = CompletionHandlerWrapper(decoder: decoder, completion: completionHandler)
        completionHandlersDispatchQueue.sync {
            _completionHandlers.append(wrapper)
        }
    }

    // MARK: - Validation

    /// :nodoc:
    private let responseValidatorsDispatchQueue = DispatchQueue(label: "Response validators")
    /// :nodoc:
    private var _responseValidators: [UBHTTPURLResponseValidator] = []
    /// The validators
    private var responseValidators: [UBHTTPURLResponseValidator] {
        return responseValidatorsDispatchQueue.sync {
            _responseValidators
        }
    }

    /// :nodoc:
    func validate(response: HTTPURLResponse) throws {
        try responseValidators.forEach { try $0.validateHTTPResponse(response) }
    }

    /// Adds a response validator.
    ///
    /// The response validator get's checked bafore any completion block is called right after the task receives the data.
    /// It can validate that the response or data are in order and can proceed for completion
    ///
    /// - Parameter validator: The validator
    public func addResponseValidator(_ validator: UBHTTPURLResponseValidator) {
        responseValidatorsDispatchQueue.sync {
            _responseValidators.append(validator)
        }
    }

    /// Adds a response validator block.
    ///
    /// The response validator get's checked bafore any completion block is called right after the task receives the data.
    /// It can validate that the response or data are in order and can proceed for completion
    ///
    /// - Parameter validationBlock: The validator block
    public func addResponseValidator(_ validationBlock: @escaping UBHTTPResponseValidatorBlock.ValidationBlock) {
        addResponseValidator(UBHTTPResponseValidatorBlock(validationBlock))
    }

    /// Adds response validators.
    ///
    /// The response validator get's checked bafore any completion block is called right after the task receives the data.
    /// It can validate that the response or data are in order and can proceed for completion
    ///
    /// - Parameter validators: An array of validators
    public func addResponseValidator(_ validators: [UBHTTPURLResponseValidator]) {
        responseValidatorsDispatchQueue.sync {
            _responseValidators.append(contentsOf: validators)
        }
    }

    // MARK: - Failure Recovery

    /// All the failure recovery strategies
    private let failureRecoveryStrategy = UBNetworkTaskRecoveryGroup()
    /// Adds a failure recovery strategy.
    ///
    /// This failure recovery strategy will be called everytime if the request has failed. The recovery is not called when the failure occurs on the decoding level. But only before the decoding stage, after the validation.
    ///
    /// - Parameter strategy: The failure recovery strategy to add
    public func addFailureRecoveryStrategy(_ strategy: UBNetworkingTaskRecoveryStrategy) {
        failureRecoveryStrategy.append(strategy)
    }

    /// :nodoc:
    private func attemptRecovery(data: Data?, response: HTTPURLResponse?, error: Error) {
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
        private let executionBlock: (Data?, HTTPURLResponse, UBNetworkingTaskInfo?, OperationQueue, UBURLDataTask) -> Void
        private let failureBlock: (Error, HTTPURLResponse?, UBNetworkingTaskInfo?, OperationQueue, UBURLDataTask) -> Void

        /// :nodoc:
        init<T>(decoder: UBURLDataTaskDecoder<T>, completion: @escaping CompletionHandlingBlock<T>) {
            // Create the block that gets called when decoding is ready
            executionBlock = { data, response, info, callbackQueue, caller in
                guard let data = data else {
                    callbackQueue.addOperation {
                        completion(.failure(UBNetworkingError.responseBodyIsEmpty), response, info, caller)
                    }
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
            failureBlock = { error, response, info, callbackQueue, caller in
                callbackQueue.addOperation {
                    completion(.failure(error), response, info, caller)
                }
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
            failureBlock = { error, response, info, callbackQueue, caller in
                callbackQueue.addOperation {
                    completion(.failure(error), response, info, caller)
                }
            }
        }

        /// :nodoc:
        func parse(data: Data?, response: HTTPURLResponse, info: UBNetworkingTaskInfo?, callbackQueue: OperationQueue, caller: UBURLDataTask) {
            executionBlock(data, response, info, callbackQueue, caller)
        }

        /// :nodoc:
        func fail(error: Error, response: HTTPURLResponse?, info: UBNetworkingTaskInfo?, callbackQueue: OperationQueue, caller: UBURLDataTask) {
            failureBlock(error, response, info, callbackQueue, caller)
        }
    }
}
