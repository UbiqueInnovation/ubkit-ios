//
//  UBURLDataTask.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// A data task that returns downloaded data directly to the app in memory.
public final class UBURLDataTask: UBURLSessionTask, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
    // MARK: - Properties

    /// The session used to create tasks
    public private(set) nonisolated(unsafe) var session: UBDataTaskURLSession
    private let sessionQueue = DispatchQueue(label: "UBURLDataTask.session")

    func setSession(_ session: UBDataTaskURLSession) {
        sessionQueue.sync {
            self.session = session
        }
    }

    /// The request to execute.
    public let request: UBURLRequest

    /// An app-provided description of the current task.
    public let taskDescription: String?

    /// Flags that will dictate how the data task will behave
    public struct Flags: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// The request will ignore caches and always load from network
        public static let ignoreCache = Flags(rawValue: 1 << 0)
        /// A task that got triggered by the system without user interaction
        public static let systemTriggered = Flags(rawValue: 1 << 1)
        /// If the task is running synchronous
        public static let synchronous = Flags(rawValue: 1 << 2)
        /// The request reloads existing data and will always load from network
        public static let refresh = Flags(rawValue: 1 << 3)
    }

    public private(set) nonisolated(unsafe) var flags: Flags = []
    private let flagsQueue = DispatchQueue(label: "UBURLDataTask.flags")

    /// The relative priority at which you’d like a host to handle the task, specified as a floating point value between 0.0 (lowest priority) and 1.0 (highest priority).
    public let priority: Float

    /// :nodoc:
    public var description: String {
        taskDescription ?? request.description
    }

    /// :nodoc:
    public var debugDescription: String {
        request.debugDescription
    }

    /// A representation of the overall task progress.
    public var progress: Progress {
        guard let progress = dataTask?.progress else {
            return Progress(totalUnitCount: 0)
        }
        return progress
    }

    /// :nodoc:
    public var countOfBytesReceived: Int64 {
        dataTask?.countOfBytesReceived ?? 0
    }

    /// The underlaying data task
    private(set) nonisolated(unsafe) var dataTask: URLSessionDataTask?
    private let dataTaskQueue = DispatchQueue(label: "UBURLDataTask.dataTask")

    /// The callback queue where all callbacks take place
    let callbackQueue: OperationQueue

    private static let syncTasksCallbackQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "UBURLDataTask Sync Callback Queue"
        q.qualityOfService = .userInitiated
        return q
    }()

    private func getCallbackQueue() -> OperationQueue {
        flagsQueue.sync {
            if flags.contains(.synchronous) {
                Self.syncTasksCallbackQueue
            } else {
                callbackQueue
            }
        }
    }

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
        _state = .initial
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
    ///   - callbackQueue: An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue. If none is provided then the callbacks are made on the main queue. Ignored for synchronous tasks.
    public convenience init(url: URL, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: UBDataTaskURLSession = Networking.sharedSession, callbackQueue: OperationQueue = .main) {
        self.init(request: UBURLRequest(url: url), taskDescription: taskDescription, priority: priority, session: session, callbackQueue: callbackQueue)
    }

    /// :nodoc:
    deinit {
        dataTaskProgressObservation?.invalidate()
        dataTaskProgressObservation = nil
        dataTaskStateObservationQueue.sync {
            dataTaskStateObservation?.invalidate()
            dataTaskStateObservation = nil
        }
        dataTaskQueue.sync {
            dataTask?.cancel()
        }
        requestStartSemaphore.signal()
        synchronousStartSemaphore.signal()
    }

    // MARK: - Startin and stopping

    // The semaphore ensuring no two threads can call start simultaniously
    private let requestStartSemaphore = DispatchSemaphore(value: 1)

    // Default start is not a refresh
    public func start() {
        start(ignoreCache: false)
    }

    /// Start the task with the given request. It will cancel any ongoing request
    public func start(ignoreCache: Bool) {
        flagsQueue.sync {
            if ignoreCache {
                flags.insert(.ignoreCache)
            } else {
                flags.remove(.ignoreCache)
            }
            flags.remove(.refresh)
        }
        let f = flagsQueue.sync { flags }
        start(flags: f)
    }

    /// Start the task with the given request. It will cancel any ongoing request
    func start(flags: Flags) {
        // Cancel the previous task
        cancel()

        // Wait for any ongoing request start
        requestStartSemaphore.wait()

        // Set the state to waiting execution and launch the task
        state = .waitingExecution

        flagsQueue.sync {
            self.flags = flags
        }

        let modifier = requestModifier

        let r = request

        requestStartSemaphore.signal()

        // Apply all modification
        modifier.modifyRequest(r) { [weak self] result in
            guard let self else {
                return
            }
            switch result {
                case let .failure(error):
                    self.attemptRecovery(data: nil, response: nil, error: error)
                case let .success(modifiedRequest):

                    if let interceptor = self.requestInterceptorQueue.sync(execute: { self._requestInterceptor }) {
                        interceptor.interceptRequest(modifiedRequest) { [weak self] interceptorResult in
                            guard let self else { return }
                            if let result = interceptorResult {
                                self.dataTaskCompleted(data: result.data, response: result.response, error: result.error, info: result.info)
                            } else {
                                self.startRequest(modifiedRequest)
                            }
                        }
                    } else {
                        self.startRequest(modifiedRequest)
                    }
            }
        }
    }

    private func startRequest(_ modifiedRequest: UBURLRequest) {
        // Create a new task from the preferences
        let dataTask = sessionQueue.sync {
            self.session.dataTask(with: modifiedRequest, owner: self)
        }
        guard let dataTask else {
            if self.state == .cancelled {
                self.state = .finished
            }
            return
        }

        // Set priority and description
        dataTask.priority = self.priority
        dataTask.taskDescription = self.taskDescription

        requestStartSemaphore.wait()

        // Observe the task progress
        self.dataTaskProgressObservation = dataTask.observe(\.progress.fractionCompleted, options: [.initial, .new], changeHandler: { [weak self] task, _ in
            guard let self else {
                return
            }

            self.notifyProgress(task.progress.fractionCompleted)
        })

        // Observe the task state
        let observation = dataTask.observe(\URLSessionDataTask.state, options: [.new], changeHandler: { [weak self] task, _ in
            switch task.state {
                case .running:
                    if self?.state != .fetching, self?.state != .cancelled {
                        self?.state = .fetching
                    }
                default:
                    break
            }
        })

        dataTaskStateObservationQueue.sync {
            self.dataTaskStateObservation = observation
        }

        dataTaskQueue.sync {
            self.dataTask = dataTask
        }

        requestStartSemaphore.signal()

        dataTask.resume()
    }

    public func cancel() {
        cancel(notifyCompletion: false)
    }

    /// Cancel the current request
    public func cancel(notifyCompletion: Bool) {
        requestStartSemaphore.wait()
        dataTaskProgressObservation = nil
        dataTaskStateObservationQueue.sync {
            dataTaskStateObservation = nil
        }
        requestStartSemaphore.signal()
        requestModifier.cancelCurrentModification()
        failureRecoveryStrategy.cancelCurrentRecovery()

        requestStartSemaphore.wait()
        dataTaskQueue.sync {
            dataTask?.cancel()
        }
        requestStartSemaphore.signal()

        switch state {
            case .initial, .parsing, .finished, .cancelled:
                break
            case .fetching, .waitingExecution:
                // don't change request state if currently starting
                requestStartSemaphore.wait()
                state = .cancelled
                requestStartSemaphore.signal()
        }

        if notifyCompletion {
            self.notifyCompletion(error: .internal(.canceled), data: nil, response: nil, info: nil)
        }
    }

    /// Called when the corresponding network call has finished loading
    ///
    /// - Parameters:
    ///   - data: The data transfered
    ///   - response: The response received with the data
    ///   - error: The error in case of failure
    func dataTaskCompleted(data: Data?, response: HTTPURLResponse?, error: Error?, info: UBNetworkingTaskInfo?) {
        guard state != .cancelled else {
            return // don't parse response after cancellation
        }

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
            attemptRecovery(data: data, response: response, error: UBInternalNetworkingError.notHTTPResponse)
            return
        }

        state = .parsing

        // We don't want to distinguish between no body and empty body
        let dataOrEmpty = data ?? Data()

        notifyCompletion(data: dataOrEmpty, response: unwrappedResponse, info: info)
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

    /// Adds a async request modifier.
    ///
    /// This modifier will be called everytime before the request is sent, and it gets a chance to modify the request.
    ///
    /// - Parameter modifier: The request modifier to add
    @discardableResult
    public func addRequestModifier(_ modifier: UBAsyncURLRequestModifier) -> Self {
        requestModifier.append(modifier)
        return self
    }

    // MARK: - Request Interceptor

    /// The request interceptor
    /// This will be called everytime before the request is sent, if it returns a result the request will be skipped and the result will be forewarded to the completion block.
    private nonisolated(unsafe) var _requestInterceptor: UBURLRequestInterceptor?
    private let requestInterceptorQueue = DispatchQueue(label: "UBURLDataTask.requestInterceptor")

    public func setRequestInterceptor(_ interceptor: UBURLRequestInterceptor?) {
        requestInterceptorQueue.sync {
            _requestInterceptor = interceptor
        }
    }

    // MARK: - State

    /// Called when the state of the task changed. First parameter is the old state, the second parameter is the new state
    public typealias StateTransitionObservationBlock = @Sendable (State, State, UBURLDataTask) -> Void
    /// Holds the state observation
    private nonisolated(unsafe) var dataTaskStateObservation: NSKeyValueObservation?
    private let dataTaskStateObservationQueue = DispatchQueue(label: "UBURLDataTask.dataTaskStateObservation")
    /// :nodoc:
    private let stateTransitionObserversQueue = DispatchQueue(label: "State Observers")
    /// :nodoc:
    private nonisolated(unsafe) var _stateTransitionObservers: [StateTransitionObservationBlock] = []
    /// Holds the state observers
    private var stateTransitionObservers: [StateTransitionObservationBlock] {
        stateTransitionObserversQueue.sync {
            _stateTransitionObservers
        }
    }

    /// The state of the task
    public enum State: CustomDebugStringConvertible, Sendable {
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
                    "Initial"
                case .waitingExecution:
                    "Waiting Execution"
                case .fetching:
                    "Fetching"
                case .parsing:
                    "Parsing"
                case .finished:
                    "Finished"
                case .cancelled:
                    "Canceled"
            }
        }
    }

    /// :nodoc:
    private let stateDispatchQueue = DispatchQueue(label: "State")
    /// :nodoc:
    private nonisolated(unsafe) var _state: State {
        willSet {
            // Validate state machine
            switch (_state, newValue) {
                case (.initial, .waitingExecution), // Put the task in the queue
                     (.waitingExecution, .fetching), // Start task
                     (.waitingExecution, .cancelled), // Cancel task
                     (.waitingExecution, .parsing), // Returned from cache
                     (.waitingExecution, .finished), // RecoverStrategy cannotRecover a RequestModifier
                     (.fetching, .parsing), // Data received
                     (.fetching, .finished), // Error received
                     (.fetching, .cancelled), // Cancel task
                     (.parsing, .finished), // Data parsed
                     (.finished, .waitingExecution), // Restart task
                     (.cancelled, .cancelled), // Cancelled
                     (.cancelled, .waitingExecution): // Restart task
                    break
                default:
                    let errorMessage = "Invalid state transition from \(_state) -> \(newValue)"
                    assertionFailure(errorMessage)
                    UBNonFatalErrorReporter.report(NSError(domain: "UBURLDataTask", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
        }
        didSet {
            notifyStateTransition(old: oldValue, new: _state)
        }
    }

    /// The current state of the task
    public private(set) var state: State {
        get {
            stateDispatchQueue.sync {
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
        self.stateTransitionObservers.forEach { observer in
            getCallbackQueue().addOperation { [weak self] in
                guard let self else {
                    return
                }
                observer(old, new, self)
            }
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
    public typealias ProgressObservationBlock = @Sendable (UBURLDataTask, Double) -> Void
    /// The progress observation holder
    private nonisolated(unsafe) var dataTaskProgressObservation: NSKeyValueObservation?
    /// :nodoc:
    private let progressObserversDispatchQueue = DispatchQueue(label: "Progress Observers")
    /// :nodoc:
    private nonisolated(unsafe) var _progressObservers: [ProgressObservationBlock] = []
    /// The progress observers
    private var progressObservers: [ProgressObservationBlock] {
        progressObserversDispatchQueue.sync {
            _progressObservers
        }
    }

    /// :nodoc:
    private func notifyProgress(_ progress: Double) {
        self.progressObservers.forEach { observer in
            getCallbackQueue().addOperation { [weak self] in
                guard let self else {
                    return
                }
                observer(self, progress)
            }
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
    public typealias CompletionHandlingBlock<T> = @Sendable (Result<T, UBNetworkingError>, HTTPURLResponse?, UBNetworkingTaskInfo?, UBURLDataTask) -> Void
    /// A completion handling block called at the end of the task.
    public typealias CompletionHandlingNullableDataBlock = @Sendable (Result<Data?, UBNetworkingError>, HTTPURLResponse?, UBNetworkingTaskInfo?, UBURLDataTask) -> Void
    /// :nodoc:
    let completionHandlersDispatchQueue = DispatchQueue(label: "Completion Handlers")

    /// Identifies a completion block
    public typealias CompletionHandlerIdentifier = UUID

    /// The completion handlers
    private nonisolated(unsafe) var _completionHandlers: [CompletionHandlerIdentifier: CompletionHandlerWrapper] = [:]

    private var completionHandlers: [CompletionHandlerWrapper] {
        completionHandlersDispatchQueue.sync {
            _completionHandlers.map(\.value)
        }
    }

    /// :nodoc:
    private func notifyCompletion(error: UBNetworkingError, data: Data?, response: HTTPURLResponse?, info: UBNetworkingTaskInfo?) {
        state = .finished
        completionHandlers.forEach { $0.fail(error: error, data: data, response: response, info: info, callbackQueue: $0.callbackQueue ?? getCallbackQueue(), caller: self) }
    }

    /// :nodoc:
    private func notifyCompletion(data: Data, response: HTTPURLResponse, info: UBNetworkingTaskInfo?) {
        state = .finished
        completionHandlers.forEach { $0.parse(data: data, response: response, info: info, callbackQueue: $0.callbackQueue ?? self.getCallbackQueue(), caller: self) }
    }

    /// A semaphore to ensure when starting a task in synchronous mode, to block the current thread
    private let synchronousStartSemaphore = DispatchSemaphore(value: 1)

    private final class ResultHolder<T: Sendable>: Sendable {
        var fetchedResult: (Result<T, UBNetworkingError>, HTTPURLResponse?, UBNetworkingTaskInfo?, UBURLDataTask)? {
            get {
                queue.sync {
                    _fetchedResult
                }
            }
            set {
                queue.sync {
                    _fetchedResult = newValue
                }
            }
        }

        private nonisolated(unsafe) var _fetchedResult: (Result<T, UBNetworkingError>, HTTPURLResponse?, UBNetworkingTaskInfo?, UBURLDataTask)?
        private let queue = DispatchQueue(label: "ResultHolder")
    }

    /// Starts the data task and blocks the current thread until a response or an error are returned
    ///
    /// - Parameter decoder: A decoder for the response
    /// - Returns: The result of the task
    @discardableResult
    public func startSynchronous<T: Sendable>(decoder: UBURLDataTaskDecoder<T>) -> (result: Result<T, UBNetworkingError>, response: HTTPURLResponse?, info: UBNetworkingTaskInfo?, dataTask: UBURLDataTask) {
        synchronousStartSemaphore.wait()

        _ = flagsQueue.sync {
            flags.insert(.synchronous)
        }

        let resultHolder = ResultHolder<T>()

        let completionBlockIdentifier = addCompletionHandler(decoder: decoder) { [weak self] result, response, taskInfo, dataTask in
            resultHolder.fetchedResult = (result, response, taskInfo, dataTask)
            self?.synchronousStartSemaphore.signal()
        }

        start()

        // timeout should fire to completion handler, but never called for cancelled requests
        // semaphore timeout to avoid deadlock
        let timeout = Int(request.timeoutInterval * 2.0)
        let waitResult = synchronousStartSemaphore.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(timeout))

        if waitResult == .timedOut {
            return (.failure(.internal(.synchronousTimedOut)), nil, nil, self)
        }

        removeCompletionHandler(identifier: completionBlockIdentifier)

        guard let unwrappedResult = resultHolder.fetchedResult else {
            return (.failure(UBNetworkingError.internal(.unwrapError)), nil, nil, self)
        }

        synchronousStartSemaphore.signal()

        _ = flagsQueue.sync {
            flags.remove(.synchronous)
        }

        return unwrappedResult
    }

    /// Starts the data task and blocks the current thread until a response or an error are returned
    ///
    /// - Returns: The result of the task
    @available(*, deprecated, message: "Use a UBDataPassthroughDecoder instead")
    @discardableResult
    public func startSynchronous() -> (result: Result<Data, UBNetworkingError>, response: HTTPURLResponse?, info: UBNetworkingTaskInfo?, dataTask: UBURLDataTask) {
        synchronousStartSemaphore.wait()

        _ = flagsQueue.sync {
            flags.insert(.synchronous)
        }

        let resultHolder = ResultHolder<Data>()

        let completionBlockIdentifier = addCompletionHandler(decoder: .passthrough) { [weak self] result, response, taskInfo, dataTask in
            resultHolder.fetchedResult = (result, response, taskInfo, dataTask)
            self?.synchronousStartSemaphore.signal()
        }

        start()

        // timeout should fire to completion handler, but never called for cancelled requests
        // semaphore timeout to avoid deadlock
        let timeout = Int(request.timeoutInterval * 2.0)
        let waitResult = synchronousStartSemaphore.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(timeout))

        if waitResult == .timedOut {
            return (Result.failure(.timedOut()), nil, nil, self)
        }

        removeCompletionHandler(identifier: completionBlockIdentifier)

        guard let unwrappedResult = resultHolder.fetchedResult else {
            return (Result.failure(.internal(.unwrapError)), nil, nil, self)
        }

        synchronousStartSemaphore.signal()

        _ = flagsQueue.sync {
            flags.remove(.synchronous)
        }

        return unwrappedResult
    }

    /// Adds a completion handler that gets the raw data as is.
    ///
    /// - Parameter completionHandler: A completion handler
    /// - Parameter callbackQueue: If not null, the queue where this specific handler will be called
    /// Returns: Identifier token that can be used to remove the handler later
    @available(*, deprecated, message: "Use a UBDataPassthroughDecoder instead")
    public func addCompletionHandler(_ completionHandler: @escaping CompletionHandlingNullableDataBlock, callbackQueue: OperationQueue? = nil) -> UUID {
        let wrapper = CompletionHandlerWrapper(completion: completionHandler, callbackQueue: callbackQueue)
        let uuid = CompletionHandlerIdentifier()
        completionHandlersDispatchQueue.sync {
            _completionHandlers[uuid] = wrapper
        }
        return uuid
    }

    /// Adds a completion handler that gets the data decoded by the specified decoder.
    ///
    /// If no data is returned, there will be an error raised and the result will fail.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - Parameter callbackQueue: If not null, the queue where this specific handler will be called
    ///   - completionHandler: A completion handler
    @discardableResult
    public func addCompletionHandler<T: Sendable>(decoder: UBURLDataTaskDecoder<T>, callbackQueue: OperationQueue? = nil, completionHandler: @escaping @Sendable CompletionHandlingBlock<T>) -> UUID {
        let wrapper = CompletionHandlerWrapper(decoder: decoder, completion: completionHandler, callbackQueue: callbackQueue)
        let uuid = CompletionHandlerIdentifier()
        completionHandlersDispatchQueue.sync {
            _completionHandlers[uuid] = wrapper
        }
        return uuid
    }

    /// Adds a completion handler that gets the data decoded by the specified decoder.
    /// In case of ab error, the handler gets the error object decoded by the spcified errorDecoder.
    ///
    /// If no data is returned, there will be an error raised and the result will fail.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - errorDecoder: The decoder for the error in case of a failed request
    ///   - completionHandler: A completion handler
    ///   - callbackQueue: If not null, where the callback will be executed
    @discardableResult
    public func addCompletionHandler<T: Sendable>(decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<some UBURLDataTaskErrorBody>, callbackQueue: OperationQueue? = nil, completionHandler: @escaping CompletionHandlingBlock<T>) -> UUID {
        let wrapper = CompletionHandlerWrapper(decoder: decoder, errorDecoder: errorDecoder, completion: completionHandler, callbackQueue: callbackQueue)
        let uuid = CompletionHandlerIdentifier()
        completionHandlersDispatchQueue.sync {
            _completionHandlers[uuid] = wrapper
        }
        return uuid
    }

    /// Removes a completion handler
    ///
    /// - Parameter identifier: The identifier returned when adding the completion block
    public func removeCompletionHandler(identifier: CompletionHandlerIdentifier) {
        completionHandlersDispatchQueue.sync {
            _ = _completionHandlers.removeValue(forKey: identifier)
        }
    }

    // MARK: - Validation

    /// :nodoc:
    private let responseValidatorsDispatchQueue = DispatchQueue(label: "Response validators")
    /// :nodoc:
    private nonisolated(unsafe) var _responseValidators: [UBHTTPURLResponseValidator] = []
    /// The validators
    private var responseValidators: [UBHTTPURLResponseValidator] {
        responseValidatorsDispatchQueue.sync {
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
                    self?.notifyCompletion(error: UBNetworkingError(error), data: data, response: response, info: nil)
                case let .recoveryOptions(options: options):
                    let error = UBNetworkingError(options)
                    self?.notifyCompletion(error: error, data: data, response: response, info: nil)
                case let .recovered(data: data, response: response, info: info):
                    self?.notifyCompletion(data: data, response: response, info: info)
                case .restartDataTask:
                    self?.start(ignoreCache: false)
            }
        }
    }
}

extension UBURLDataTask {
    /// This is a wrapper that holds reference for a completion handler
    private struct CompletionHandlerWrapper {
        private let executionBlock: (Data, HTTPURLResponse, UBNetworkingTaskInfo?, OperationQueue, UBURLDataTask) -> Void
        private let failureBlock: (UBNetworkingError, Data?, HTTPURLResponse?, UBNetworkingTaskInfo?, OperationQueue, UBURLDataTask) -> Void
        let callbackQueue: OperationQueue?

        /// :nodoc:
        init<T: Sendable>(decoder: UBURLDataTaskDecoder<T>, completion: @escaping @Sendable CompletionHandlingBlock<T>, callbackQueue: OperationQueue?) {
            self.callbackQueue = callbackQueue
            // Create the block that gets called when decoding is ready
            executionBlock = { data, response, info, callbackQueue, caller in
                do {
                    let decoded = try decoder.decode(data: data, response: response)
                    callbackQueue.addOperation {
                        completion(.success(decoded), response, info, caller)
                    }
                } catch {
                    callbackQueue.addOperation {
                        completion(.failure(UBNetworkingError(error)), response, info, caller)
                    }
                }
            }

            // Create a block to be called on failure
            failureBlock = { error, _, response, info, callbackQueue, caller in
                callbackQueue.addOperation {
                    completion(.failure(UBNetworkingError(error)), response, info, caller)
                }
            }
        }

        /// :nodoc:
        init<T: Sendable>(decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<some UBURLDataTaskErrorBody>, completion: @escaping CompletionHandlingBlock<T>, callbackQueue: OperationQueue?) {
            self.callbackQueue = callbackQueue
            // Create the block that gets called when decoding is ready
            executionBlock = { data, response, info, callbackQueue, caller in
                do {
                    let decoded = try decoder.decode(data: data, response: response)
                    callbackQueue.addOperation {
                        completion(.success(decoded), response, info, caller)
                    }
                } catch {
                    callbackQueue.addOperation {
                        completion(.failure(UBNetworkingError(error)), response, info, caller)
                    }
                }
            }

            // Create a block to be called on failure
            failureBlock = { error, data, response, info, callbackQueue, caller in
                let newError: Error
                if let data, let response {
                    var decodedError = try? errorDecoder.decode(data: data, response: response)
                    decodedError?.baseError = error
                    newError = decodedError ?? error
                } else {
                    newError = error
                }
                callbackQueue.addOperation {
                    completion(.failure(UBNetworkingError(newError)), response, info, caller)
                }
            }
        }

        /// :nodoc:
        init(completion: @escaping CompletionHandlingNullableDataBlock, callbackQueue: OperationQueue?) {
            self.callbackQueue = callbackQueue
            // Create the block that gets called when success
            executionBlock = { data, response, info, callbackQueue, caller in
                callbackQueue.addOperation {
                    completion(.success(data), response, info, caller)
                }
            }
            // Create a block to be called on failure
            failureBlock = { error, _, response, info, callbackQueue, caller in
                callbackQueue.addOperation {
                    completion(.failure(error), response, info, caller)
                }
            }
        }

        /// :nodoc:
        func parse(data: Data, response: HTTPURLResponse, info: UBNetworkingTaskInfo?, callbackQueue: OperationQueue, caller: UBURLDataTask) {
            executionBlock(data, response, info, callbackQueue, caller)
        }

        /// :nodoc:
        func fail(error: UBNetworkingError, data: Data?, response: HTTPURLResponse?, info: UBNetworkingTaskInfo?, callbackQueue: OperationQueue, caller: UBURLDataTask) {
            failureBlock(error, data, response, info, callbackQueue, caller)
        }
    }
}
