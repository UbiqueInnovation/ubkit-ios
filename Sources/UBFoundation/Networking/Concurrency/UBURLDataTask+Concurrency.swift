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
        let info: UBNetworkingTaskInfo?
        let response: HTTPURLResponse?
    }

    private static let concurrencyCallbackQueue = OperationQueue()

    func loadOnce<T>(decoder: UBURLDataTaskDecoder<T>) async throws -> (result: T, meta: MetaData) {

        return try await withCheckedThrowingContinuation { cont in

            var id: UUID?

            id = self.addCompletionHandler(decoder: decoder) { result, response, info, task in
                switch result {
                case let .success(res):
                        cont.resume(returning: (result: res, meta: MetaData(info: info, response: response)))
                case let .failure(e):
                    cont.resume(throwing: e)
                }
                if let id = id {
                    self.removeCompletionHandler(identifier: id)
                }
            }
            self.start()
        }
    }

    func loadOnce() async throws -> (Data, MetaData) {
        try await self.loadOnce(decoder: UBDataPassthroughDecoder())
    }

    func startCronStream<T>(decoder: UBURLDataTaskDecoder<T>) -> AsyncThrowingStream<(T, MetaData), Error> {
        AsyncThrowingStream { cont in
            let task = UBURLDataTask(request: request, taskDescription: taskDescription, priority: priority, session: session, callbackQueue: Self.concurrencyCallbackQueue)
            let id = task.addCompletionHandler(decoder: decoder) { result, response, info, task in
                switch result {
                case let .success(res):
                        cont.yield((res, MetaData(info: info, response: response)))
                case let .failure(e):
                    cont.finish(throwing: e)
                }
            }

            cont.onTermination = { @Sendable _ in
                task.cancel()
                task.removeCompletionHandler(identifier: id)
            }
            task.start()
        }
    }

    func startCronStream() -> AsyncThrowingStream<(Data, MetaData), Error> {
        self.startCronStream(decoder: UBDataPassthroughDecoder())
    }
}
