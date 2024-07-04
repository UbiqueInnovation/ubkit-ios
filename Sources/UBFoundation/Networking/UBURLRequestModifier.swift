//
//  UBURLRequestModifier.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 01.04.19.
//

import Foundation

/// A request modifier is called before a HTTPDataTask starts and have the chance to change the request.
public protocol UBURLRequestModifier: Sendable {
    /// Modifies the request before it will start.
    ///
    /// - Parameters:
    ///   - originalRequest: The original request before modification or the most recent request updated by the previous modifiers.
    ///   - completion: The completion handler to be called when the modification are finished.
    func modifyRequest(_ originalRequest: UBURLRequest, completion: @escaping (Result<UBURLRequest, Error>) -> Void)
}

/// A request modifier is called before a HTTPDataTask starts and have the chance to change the request.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, *)
public protocol UBAsyncURLRequestModifier: UBURLRequestModifier {
    /// Modifies the request before it will start.
    ///
    /// - Parameters:
    ///   - originalRequest: The original request before modification or the most recent request updated by the previous modifiers.
    ///   - completion: The completion handler to be called when the modification are finished.
    func modifyRequest(_ request: inout UBURLRequest) async throws
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, *)
public extension UBAsyncURLRequestModifier {
    func modifyRequest(_ originalRequest: UBURLRequest, completion: @escaping @Sendable (Result<UBURLRequest, Error>) -> Void) {
        Task {
            do {
                var newRequest = originalRequest
                try await modifyRequest(&newRequest)
                completion(.success(newRequest))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
