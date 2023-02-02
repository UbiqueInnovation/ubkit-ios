//
//  File.swift
//
//
//  Created by Nicolas Märki on 16.05.22.
//

import Foundation

@available(iOS 13.0, *)
public extension UBURLDataTask {
    struct MetaData {
        public let info: UBNetworkingTaskInfo?
        public let response: HTTPURLResponse?
    }

    typealias ResultTuple<T> = (result: Result<T, UBNetworkingError>, metadata: UBURLDataTask.MetaData)

    class TaskConfig {
        public init(requestModifiers: [UBURLRequestModifier] = [], requestInterceptor: UBURLRequestInterceptor? = nil, failureRecoveryStrategies: [UBNetworkingTaskRecoveryStrategy] = [], session: UBDataTaskURLSession? = nil) {
            self.requestModifiers = requestModifiers
            self.requestInterceptor = requestInterceptor
            self.failureRecoveryStrategies = failureRecoveryStrategies
            self.session = session
        }

        public var requestModifiers: [UBURLRequestModifier] = []
        public var requestInterceptor: UBURLRequestInterceptor?
        public var failureRecoveryStrategies: [UBNetworkingTaskRecoveryStrategy] = []
        public var session: UBDataTaskURLSession? = nil

        @discardableResult
        public func with(requestModifier: UBURLRequestModifier) -> TaskConfig {
            requestModifiers.append(requestModifier)
            return self
        }

        @discardableResult
        public func with(requestInterceptor: UBURLRequestInterceptor) -> TaskConfig {
            self.requestInterceptor = requestInterceptor
            return self
        }

        @discardableResult
        public func with(failureRecoveryStrategy: UBNetworkingTaskRecoveryStrategy) -> TaskConfig {
            failureRecoveryStrategies.append(failureRecoveryStrategy)
            return self
        }

        @discardableResult
        public func with(session: UBDataTaskURLSession) -> TaskConfig {
            self.session = session
            return self
        }
    }

    static func with(requestModifier: UBURLRequestModifier) -> TaskConfig {
        return TaskConfig(requestModifiers: [requestModifier])
    }

    static func with(requestInterceptor: UBURLRequestInterceptor) -> TaskConfig {
        return TaskConfig(requestInterceptor: requestInterceptor)
    }

    static func with(failureRecoveryStrategy: UBNetworkingTaskRecoveryStrategy) -> TaskConfig {
        return TaskConfig(failureRecoveryStrategies: [failureRecoveryStrategy])
    }

    static func with(session: UBDataTaskURLSession) -> TaskConfig {
        return TaskConfig(session: session)
    }

    struct TaskResult<T> {
        internal init(resultTuple: ResultTuple<T>) {
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
            return resultTuple.metadata
        }

        /// Optional networking error of a failed request
        public var ubNetworkingError: UBNetworkingError? {
            if case .failure(let error) = resultTuple.result {
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
    static func loadOnce<T>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, ignoreCache: Bool = false, taskConfig: TaskConfig = TaskConfig()) async -> TaskResult<T> {
        let task = UBURLDataTask(request: request)

        for requestModifier in taskConfig.requestModifiers {
            task.addRequestModifier(requestModifier)
        }

        task.requestInterceptor = taskConfig.requestInterceptor

        for strategy in taskConfig.failureRecoveryStrategies {
            task.addFailureRecoveryStrategy(strategy)
        }

        if let session = taskConfig.session {
            task.setSession(session)
        }

        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { cont in
                var id: UUID?

                id = task.addCompletionHandler(decoder: decoder, callbackQueue: Self.concurrencyCallbackQueue) { result, response, info, task in
                    switch result {
                        case let .success(res):
                            cont.resume(returning: TaskResult(resultTuple: (.success(res), MetaData(info: info, response: response))))
                        case let .failure(e):
                            cont.resume(returning: TaskResult(resultTuple: (.failure(e), MetaData(info: info, response: response))))
                    }
                    if let id = id {
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
    static func loadOnce<T, E: UBURLDataTaskErrorBody>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<E>, ignoreCache: Bool = false, taskConfig: TaskConfig = TaskConfig()) async -> TaskResult<T> {
        let task = UBURLDataTask(request: request)

        for requestModifier in taskConfig.requestModifiers {
            task.addRequestModifier(requestModifier)
        }

        task.requestInterceptor = taskConfig.requestInterceptor

        for strategy in taskConfig.failureRecoveryStrategies {
            task.addFailureRecoveryStrategy(strategy)
        }

        if let session = taskConfig.session {
            task.setSession(session)
        }

        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { cont in
                var id: UUID?
                id = task.addCompletionHandler(decoder: decoder, errorDecoder: errorDecoder, callbackQueue: Self.concurrencyCallbackQueue) { result, response, info, task in
                    switch result {
                        case let .success(res):
                            cont.resume(returning: TaskResult(resultTuple: (.success(res), MetaData(info: info, response: response))))
                        case let .failure(e):
                            cont.resume(returning: TaskResult(resultTuple: (.failure(e), MetaData(info: info, response: response))))
                    }
                    if let id = id {
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
    @discardableResult
    static func loadOnce(request: UBURLRequest, ignoreCache: Bool = false, taskConfig: TaskConfig = TaskConfig()) async -> TaskResult<Data> {
        await UBURLDataTask.loadOnce(request: request, decoder: UBDataPassthroughDecoder(), ignoreCache: ignoreCache, taskConfig: taskConfig)
    }

    /// Starts a stream of requests which will be executed repeatedly based on next-refresh header
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    /// - Returns: A throwing stream of decoded result object with metadata
    func startStream<T>(decoder: UBURLDataTaskDecoder<T>) -> AsyncThrowingStream<(T, MetaData), Error> {
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
    func startStream<T, E: UBURLDataTaskErrorBody>(decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<E>) -> AsyncThrowingStream<(T, MetaData), Error> {
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
    func startStream() -> AsyncThrowingStream<(Data, MetaData), Error> {
        self.startStream(decoder: UBDataPassthroughDecoder())
    }
}

@available(iOS 13.0, *)
public extension UBURLDataTask.TaskConfig {

    /// Makes a request and returns a TaskResult, from which you can access the data and metadata
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - ignoreCache: Whether to ignore the cache or not
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    @discardableResult
    func loadOnce<T>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, ignoreCache: Bool = false) async -> UBURLDataTask.TaskResult<T> {
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
    func loadOnce<T, E: UBURLDataTaskErrorBody>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<E>, ignoreCache: Bool = false) async -> UBURLDataTask.TaskResult<T> {
        await UBURLDataTask.loadOnce(request: request, decoder: decoder, errorDecoder: errorDecoder, ignoreCache: ignoreCache, taskConfig: self)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - request: A HTTP URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - ignoreCache: Whether to ignore the cache or not
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @discardableResult
    func loadOnce(request: UBURLRequest, ignoreCache: Bool = false) async -> UBURLDataTask.TaskResult<Data> {
        await UBURLDataTask.loadOnce(request: request, decoder: UBDataPassthroughDecoder(), ignoreCache: ignoreCache, taskConfig: self)
    }
}

// MARK: - Convenience

@available(iOS 13.0, *)
public extension URL {
    /// Makes a request and returns a TaskResult, from which you can access the data and metadata
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - timeoutInterval: The timeout interval for the request. The default is 60.0.
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    @discardableResult
    func ub_loadOnce<T>(decoder: UBURLDataTaskDecoder<T>, ignoreCache: Bool = false, timeOutInterval: TimeInterval = 60.0, taskConfig: UBURLDataTask.TaskConfig = .init()) async -> UBURLDataTask.TaskResult<T> {
        await UBURLDataTask.loadOnce(request: UBURLRequest(url: self, timeoutInterval: timeOutInterval), decoder: decoder, ignoreCache: ignoreCache, taskConfig: taskConfig)
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
    @discardableResult
    func ub_loadOnce<T, E: UBURLDataTaskErrorBody>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<E>, ignoreCache: Bool = false, timeOutInterval: TimeInterval = 60.0, taskConfig: UBURLDataTask.TaskConfig = .init()) async -> UBURLDataTask.TaskResult<T> {
        await UBURLDataTask.loadOnce(request: UBURLRequest(url: self, timeoutInterval: timeOutInterval), decoder: decoder, errorDecoder: errorDecoder, ignoreCache: ignoreCache, taskConfig: taskConfig)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - timeoutInterval: The timeout interval for the request. The default is 60.0.
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @discardableResult
    func ub_loadOnce(request: UBURLRequest, ignoreCache: Bool = false, timeOutInterval: TimeInterval = 60.0, taskConfig: UBURLDataTask.TaskConfig = .init()) async -> UBURLDataTask.TaskResult<Data> {
        await UBURLDataTask.loadOnce(request: UBURLRequest(url: self, timeoutInterval: timeOutInterval), decoder: UBDataPassthroughDecoder(), ignoreCache: ignoreCache, taskConfig: taskConfig)
    }
}

@available(iOS 13.0, *)
public extension UBURLRequest {
    /// Makes a request and returns a TaskResult, from which you can access the data and metadata
    /// - Parameters:
    ///   - decoder: The decoder to transform the data. The decoder is called on a secondary thread.
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - timeoutInterval: The timeout interval for the request. The default is 60.0.
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    @discardableResult
    func loadOnce<T>(decoder: UBURLDataTaskDecoder<T>, ignoreCache: Bool = false, timeOutInterval: TimeInterval = 60.0, taskConfig: UBURLDataTask.TaskConfig = .init()) async -> UBURLDataTask.TaskResult<T> {
        await UBURLDataTask.loadOnce(request: self, decoder: decoder, ignoreCache: ignoreCache, taskConfig: taskConfig)
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
    @discardableResult
    func loadOnce<T, E: UBURLDataTaskErrorBody>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<E>, ignoreCache: Bool = false, taskConfig: UBURLDataTask.TaskConfig = .init()) async -> UBURLDataTask.TaskResult<T> {
        await UBURLDataTask.loadOnce(request: self, decoder: decoder, errorDecoder: errorDecoder, ignoreCache: ignoreCache, taskConfig: taskConfig)
    }

    /// Makes a request and returns a TaskResult consisting of Data
    /// - Parameters:
    ///   - ignoreCache: Whether to ignore the cache or not
    ///   - timeoutInterval: The timeout interval for the request. The default is 60.0.
    ///   - taskConfig: Optional task configurations, such as requestModifiers or requestInterceptors
    /// - Returns: `TaskResult`. Access data by result.data (throwing!)
    ///
    @discardableResult
    func loadOnce(request: UBURLRequest, ignoreCache: Bool = false, taskConfig: UBURLDataTask.TaskConfig = .init()) async -> UBURLDataTask.TaskResult<Data> {
        await UBURLDataTask.loadOnce(request: self, decoder: UBDataPassthroughDecoder(), ignoreCache: ignoreCache, taskConfig: taskConfig)
    }
}
