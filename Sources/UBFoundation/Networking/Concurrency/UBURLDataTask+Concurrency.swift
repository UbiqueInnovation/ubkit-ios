//
//  UBURLDataTask+Concurrency.swift
//
//
//  Created by Nicolas Märki on 16.05.22.
//

import Foundation

public extension UBURLDataTask {
    struct MetaData: Sendable {
        public let info: UBNetworkingTaskInfo?
        public let response: HTTPURLResponse?
    }

    typealias ResultTuple<T> = (result: Result<T, UBNetworkingError>, metadata: UBURLDataTask.MetaData)

    struct TaskConfig: Sendable {
        public init(requestModifiers: [UBURLRequestModifier] = [], requestInterceptor: UBURLRequestInterceptor? = nil, failureRecoveryStrategies: [UBNetworkingTaskRecoveryStrategy] = [], session: UBDataTaskURLSession? = nil) {
            self.requestModifiers = requestModifiers
            self.requestInterceptor = requestInterceptor
            self.failureRecoveryStrategies = failureRecoveryStrategies
            self.session = session
        }

        public var requestModifiers: [UBURLRequestModifier] = []
        public var requestInterceptor: UBURLRequestInterceptor?
        public var failureRecoveryStrategies: [UBNetworkingTaskRecoveryStrategy] = []
        public var session: UBDataTaskURLSession?

        public func with(requestModifier: UBURLRequestModifier) -> TaskConfig {
            var copy = self
            copy.requestModifiers.append(requestModifier)
            return copy
        }

        public func with(requestInterceptor: UBURLRequestInterceptor) -> TaskConfig {
            var copy = self
            copy.requestInterceptor = requestInterceptor
            return copy
        }

        public func with(failureRecoveryStrategy: UBNetworkingTaskRecoveryStrategy) -> TaskConfig {
            var copy = self
            copy.failureRecoveryStrategies.append(failureRecoveryStrategy)
            return copy
        }

        public func with(session: UBDataTaskURLSession) -> TaskConfig {
            var copy = self
            copy.session = session
            return copy
        }
    }

    static func with(requestModifier: UBURLRequestModifier) -> TaskConfig {
        TaskConfig(requestModifiers: [requestModifier])
    }

    static func with(requestInterceptor: UBURLRequestInterceptor) -> TaskConfig {
        TaskConfig(requestInterceptor: requestInterceptor)
    }

    static func with(failureRecoveryStrategy: UBNetworkingTaskRecoveryStrategy) -> TaskConfig {
        TaskConfig(failureRecoveryStrategies: [failureRecoveryStrategy])
    }

    static func with(session: UBDataTaskURLSession) -> TaskConfig {
        TaskConfig(session: session)
    }

    struct TaskResult<T: Sendable>: Sendable {
        init(resultTuple: ResultTuple<T>) {
            self.resultTuple = resultTuple
        }

        private let resultTuple: ResultTuple<T>

        /// Data of a successful request
        /// - Throws: if Result is a failure
        public var data: T {
            get throws {
                try resultTuple.result.get()
            }
        }

        /// Metadata consisting of info and reponse of a successful request
        public var metadata: MetaData {
            resultTuple.metadata
        }

        /// Optional networking error of a failed request
        public var ubNetworkingError: UBNetworkingError? {
            if case let .failure(error) = resultTuple.result {
                return error
            }
            return nil
        }
    }

    private static let concurrencyCallbackQueue = OperationQueue()

    /// Makes a request and returns a TaskResult, from which you can access the data and metadata
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    static func loadOnce<T: Sendable>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, ignoreCache: Bool = false, taskConfig: TaskConfig = TaskConfig()) async -> TaskResult<T> {
        let task = UBURLDataTask(request: request)

        for requestModifier in taskConfig.requestModifiers {
            task.addRequestModifier(requestModifier)
        }

        task.setRequestInterceptor(taskConfig.requestInterceptor)

        for strategy in taskConfig.failureRecoveryStrategies {
            task.addFailureRecoveryStrategy(strategy)
        }

        if let session = taskConfig.session {
            task.setSession(session)
        }

        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { cont in
                let id: UUID? = task.addCompletionHandler(decoder: decoder, callbackQueue: Self.concurrencyCallbackQueue) { result, response, info, task in
                    switch result {
                        case let .success(res):
                            cont.resume(returning: TaskResult(resultTuple: (.success(res), MetaData(info: info, response: response))))
                        case let .failure(e):
                            cont.resume(returning: TaskResult(resultTuple: (.failure(e), MetaData(info: info, response: response))))
                    }
                    if let id {
                        task.removeCompletionHandler(identifier: id)
                    }
                }
                task.start(ignoreCache: ignoreCache)
            }
        }, onCancel: {
            task.cancel()
        })
    }

    /// Makes a request and returns a TaskResult, from which you can access the data and metadata
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - errorDecoder: The decoder for the error in case of a failed request
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    static func loadOnce<T: Sendable>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<some UBURLDataTaskErrorBody>, ignoreCache: Bool = false, taskConfig: TaskConfig = TaskConfig()) async -> TaskResult<T> {
        let task = UBURLDataTask(request: request)

        for requestModifier in taskConfig.requestModifiers {
            task.addRequestModifier(requestModifier)
        }

        task.setRequestInterceptor(taskConfig.requestInterceptor)

        for strategy in taskConfig.failureRecoveryStrategies {
            task.addFailureRecoveryStrategy(strategy)
        }

        if let session = taskConfig.session {
            task.setSession(session)
        }

        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { cont in
                let id: UUID? = task.addCompletionHandler(decoder: decoder, errorDecoder: errorDecoder, callbackQueue: Self.concurrencyCallbackQueue) { result, response, info, task in
                    switch result {
                        case let .success(res):
                            cont.resume(returning: TaskResult(resultTuple: (.success(res), MetaData(info: info, response: response))))
                        case let .failure(e):
                            cont.resume(returning: TaskResult(resultTuple: (.failure(e), MetaData(info: info, response: response))))
                    }
                    if let id {
                        task.removeCompletionHandler(identifier: id)
                    }
                }
                task.start(ignoreCache: ignoreCache)
            }
        }, onCancel: {
            task.cancel()
        })
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @available(*, deprecated, message: "Use a UBDataPassthroughDecoder instead")
    @discardableResult
    static func loadOnce(request: UBURLRequest, ignoreCache: Bool = false, taskConfig: TaskConfig = TaskConfig()) async -> TaskResult<Data> {
        await UBURLDataTask.loadOnce(request: request, decoder: .passthrough, ignoreCache: ignoreCache, taskConfig: taskConfig)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - url: A URL that represents the request to execute.
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @discardableResult
    static func loadOnce<T: Sendable>(url: URL, decoder: UBURLDataTaskDecoder<T>, ignoreCache: Bool = false, taskConfig: TaskConfig = TaskConfig()) async -> TaskResult<T> {
        await UBURLDataTask.loadOnce(request: UBURLRequest(url: url), decoder: decoder, ignoreCache: ignoreCache, taskConfig: taskConfig)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - url: A URL that represents the request to execute.
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - errorDecoder: The decoder for the error in case of a failed request
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @discardableResult
    static func loadOnce<T: Sendable>(url: URL, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<some UBURLDataTaskErrorBody>, ignoreCache: Bool = false, taskConfig: TaskConfig = TaskConfig()) async -> TaskResult<T> {
        await UBURLDataTask.loadOnce(request: UBURLRequest(url: url), decoder: decoder, errorDecoder: errorDecoder, ignoreCache: ignoreCache, taskConfig: taskConfig)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - url: A URL that represents the request to execute.
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @available(*, deprecated, message: "Use a UBDataPassthroughDecoder instead")
    @discardableResult
    static func loadOnce(url: URL, ignoreCache: Bool = false, taskConfig: TaskConfig = TaskConfig()) async -> TaskResult<Data> {
        await UBURLDataTask.loadOnce(request: UBURLRequest(url: url), decoder: .passthrough, ignoreCache: ignoreCache, taskConfig: taskConfig)
    }

    /// Starts a stream of requests which will be executed repeatedly based on next-refresh header
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    /// - Returns: A throwing stream of decoded result object with metadata
    func startStream<T: Sendable>(decoder: UBURLDataTaskDecoder<T>) -> AsyncThrowingStream<(T, MetaData), Error> {
        AsyncThrowingStream { cont in
            let id = self.addCompletionHandler(decoder: decoder, callbackQueue: Self.concurrencyCallbackQueue) { result, response, info, task in
                switch result {
                    case let .success(res):
                        cont.yield((res, MetaData(info: info, response: response)))
                    case let .failure(e):
                        cont.finish(throwing: e)
                }
            }

            cont.onTermination = { @Sendable [self] _ in
                self.cancel()
                self.removeCompletionHandler(identifier: id)
            }

            self.start()
        }
    }

    /// Starts a stream of requests which will be executed repeatedly based on next-refresh header
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - errorDecoder: The decoder for the error in case of a failed request
    /// - Returns: A throwing stream of decoded result object with metadata
    func startStream<T: Sendable>(decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<some UBURLDataTaskErrorBody>) -> AsyncThrowingStream<(T, MetaData), Error> {
        AsyncThrowingStream { [self] cont in
            let id = self.addCompletionHandler(decoder: decoder, errorDecoder: errorDecoder, callbackQueue: Self.concurrencyCallbackQueue) { result, response, info, task in
                switch result {
                    case let .success(res):
                        cont.yield((res, MetaData(info: info, response: response)))
                    case let .failure(e):
                        cont.finish(throwing: e)
                }
            }

            cont.onTermination = { @Sendable [self] _ in
                self.cancel()
                self.removeCompletionHandler(identifier: id)
            }
            self.start()
        }
    }

    /// Starts a stream of requests which will be executed repeatedly based on next-refresh header
    /// - Returns: A throwing stream of data with metadata
    @available(*, deprecated, message: "Use a UBDataPassthroughDecoder instead")
    func startStream() -> AsyncThrowingStream<(Data, MetaData), Error> {
        self.startStream(decoder: .passthrough)
    }
}

public extension UBURLDataTask.TaskConfig {
    /// Makes a request and returns a TaskResult, from which you can access the data and metadata
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - ignoreCache: Whether to ignore the cache or not
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    @discardableResult
    func loadOnce<T: Sendable>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, ignoreCache: Bool = false) async -> UBURLDataTask.TaskResult<T> {
        await UBURLDataTask.loadOnce(request: request, decoder: decoder, ignoreCache: ignoreCache, taskConfig: self)
    }

    /// Makes a request and returns a TaskResult, from which you can access the data and metadata
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - errorDecoder: The decoder for the error in case of a failed request
    ///   - ignoreCache: Whether to ignore the cache or not
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @discardableResult
    func loadOnce<T: Sendable>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<some UBURLDataTaskErrorBody>, ignoreCache: Bool = false) async -> UBURLDataTask.TaskResult<T> {
        await UBURLDataTask.loadOnce(request: request, decoder: decoder, errorDecoder: errorDecoder, ignoreCache: ignoreCache, taskConfig: self)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - ignoreCache: Whether to ignore the cache or not
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @available(*, deprecated, message: "Use a UBDataPassthroughDecoder instead")
    @discardableResult
    func loadOnce(request: UBURLRequest, ignoreCache: Bool = false) async -> UBURLDataTask.TaskResult<Data> {
        await UBURLDataTask.loadOnce(request: request, decoder: .passthrough, ignoreCache: ignoreCache, taskConfig: self)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - url: A URL that represents the request to execute.
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - ignoreCache: Whether to ignore the cache or not
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @discardableResult
    func loadOnce<T: Sendable>(url: URL, decoder: UBURLDataTaskDecoder<T>, ignoreCache: Bool = false) async -> UBURLDataTask.TaskResult<T> {
        await UBURLDataTask.loadOnce(request: UBURLRequest(url: url), decoder: decoder, ignoreCache: ignoreCache, taskConfig: self)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - url: A URL that represents the request to execute.
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - errorDecoder: The decoder for the error in case of a failed request
    ///   - ignoreCache: Whether to ignore the cache or not
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @discardableResult
    func loadOnce<T: Sendable>(url: URL, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<some UBURLDataTaskErrorBody>, ignoreCache: Bool = false) async -> UBURLDataTask.TaskResult<T> {
        await UBURLDataTask.loadOnce(request: UBURLRequest(url: url), decoder: decoder, errorDecoder: errorDecoder, ignoreCache: ignoreCache, taskConfig: self)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - url: A URL that represents the request to execute.
    ///   - ignoreCache: Whether to ignore the cache or not
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @available(*, deprecated, message: "Use a UBDataPassthroughDecoder instead")
    @discardableResult
    func loadOnce(url: URL, ignoreCache: Bool = false) async -> UBURLDataTask.TaskResult<Data> {
        await UBURLDataTask.loadOnce(request: UBURLRequest(url: url), decoder: .passthrough, ignoreCache: ignoreCache, taskConfig: self)
    }
}
