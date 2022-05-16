//
//  File.swift
//  
//
//  Created by Nicolas Märki on 16.05.22.
//

import Foundation

@available(iOS 13.0, *)
public extension UBURLDataTask {

    private static let concurrencyCallbackQueue = OperationQueue()

    static func loadOnce<T>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: UBDataTaskURLSession = Networking.sharedSession) async throws -> (T, UBNetworkingTaskInfo?) {

        let task = UBURLDataTask(request: request, taskDescription: taskDescription, priority: priority, session: session, callbackQueue: Self.concurrencyCallbackQueue)
        
        return try await withCheckedThrowingContinuation { cont in

            task.addCompletionHandler(decoder: decoder) { result, response, info, task in
                switch result {
                    case let .success(res):
                        cont.resume(returning: (res, info))
                    case let .failure(e):
                        cont.resume(throwing: e)
                }
            }
            task.start()
        }

    }

    static func loadOnce(request: UBURLRequest, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: UBDataTaskURLSession = Networking.sharedSession) async throws -> (Data, UBNetworkingTaskInfo?) {
        try await Self.loadOnce(request: request, decoder: UBDataPassthroughDecoder(), taskDescription: taskDescription, priority: priority, session: session)
    }

    static func startCronStream<T>(request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: UBDataTaskURLSession = Networking.sharedSession) -> AsyncThrowingStream<T, Error> {

        AsyncThrowingStream { cont in
            let task = UBURLDataTask(request: request, taskDescription: taskDescription, priority: priority, session: session, callbackQueue: Self.concurrencyCallbackQueue)
            task.addCompletionHandler(decoder: decoder) { result, response, info, task in
                switch result {
                    case let .success(res):
                        cont.yield(res)
                    case let .failure(e):
                        cont.finish(throwing: e)
                }
            }
            
            cont.onTermination = { @Sendable _ in
                task.cancel()
            }
            task.start()
        }
    }

    static func startCronStream(request: UBURLRequest, taskDescription: String? = nil, priority: Float = URLSessionTask.defaultPriority, session: UBDataTaskURLSession = Networking.sharedSession) -> AsyncThrowingStream<Data, Error> {
        Self.startCronStream(request: request, decoder: UBDataPassthroughDecoder(), taskDescription: taskDescription, priority: priority, session: session)
    }
}
