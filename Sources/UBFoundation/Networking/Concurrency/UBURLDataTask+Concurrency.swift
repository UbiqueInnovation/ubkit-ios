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

    struct TaskConfig {
        public init(requestModifiers: [UBURLRequestModifier] = [], requestInterceptor: UBURLRequestInterceptor? = nil) {
            self.requestModifiers = requestModifiers
            self.requestInterceptor = requestInterceptor
        }

        public var requestModifiers: [UBURLRequestModifier] = []
        public var requestInterceptor: UBURLRequestInterceptor?
    }

    struct TaskResult<T> {
        internal init(result: Result<(T, UBURLDataTask.MetaData), UBNetworkingError>) {
            self.result = result
        }

        private let result: Result<(T, MetaData), UBNetworkingError>

        /// Data of a successful request
        /// - Throws: if Result is a failure
        public var data: T {
            get throws {
                try result.get().0
            }
        }

        /// Metadata consisting of info and reponse of a successful request
        /// - Throws: if Result is a failure
        public var metadata: MetaData {
            get throws {
                try result.get().1
            }
        }

        /// Optional networking error of a failed request
        public var ubNetworkingError: UBNetworkingError? {
            switch result {
                case let .failure(error):
                    return error
                default:
                    return nil
            }
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

        return await withCheckedContinuation { cont in
            var id: UUID?

            id = task.addCompletionHandler(decoder: decoder, callbackQueue: Self.concurrencyCallbackQueue) { result, response, info, task in
                switch result {
                    case let .success(res):
                        cont.resume(returning: TaskResult(result:.success((res, MetaData(info: info, response: response)))))
                    case let .failure(e):
                        cont.resume(returning: TaskResult(result: .failure(e)))
                }
                if let id = id {
                    task.removeCompletionHandler(identifier: id)
                }
            }
            task.start(ignoreCache: ignoreCache)
        }
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
        return await withCheckedContinuation { cont in
            var id: UUID?



            id = task.addCompletionHandler(decoder: decoder, errorDecoder: errorDecoder, callbackQueue: Self.concurrencyCallbackQueue) { result, response, info, task in
                switch result {
                case let .success(res):
                        cont.resume(returning: TaskResult(result:.success((res, MetaData(info: info, response: response)))))
                case let .failure(e):
                        cont.resume(returning: TaskResult(result: .failure(e)))
                }
                if let id = id {
                    task.removeCompletionHandler(identifier: id)
                }
            }
            task.start(ignoreCache: ignoreCache)
        }
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

    func startCronStream<T>(decoder: UBURLDataTaskDecoder<T>) -> AsyncThrowingStream<(T, MetaData), Error> {
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

    func startCronStream<T, E: UBURLDataTaskErrorBody>(decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<E>) -> AsyncThrowingStream<(T, MetaData), Error> {
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

    func startCronStream() -> AsyncThrowingStream<(Data, MetaData), Error> {
        self.startCronStream(decoder: UBDataPassthroughDecoder())
    }
}
