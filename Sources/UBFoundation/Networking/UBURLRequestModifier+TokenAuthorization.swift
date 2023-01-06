//
//  UBURLRequestModifier+TokenAuthorization.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 01.04.19.
//

import Foundation

/// A protocol describing a token authorisation request modifier
public protocol UBURLRequestTokenAuthorization: UBURLRequestModifier {
    /// Fetches the token and returns it
    ///
    /// - Parameter completion: The completion should be called with success or failure
    func getToken(completion: @escaping (Result<String, Error>) -> Void)
}

public extension UBURLRequestTokenAuthorization {
    /// :nodoc:
    func modifyRequest(_ originalRequest: UBURLRequest, completion: @escaping (Result<UBURLRequest, Error>) -> Void) {
        getToken { result in
            var modifierRequest = originalRequest
            switch result {
                case let .success(token):
                    modifierRequest.setHTTPHeaderField(UBHTTPHeaderField(key: .authorization, value: "Bearer \(token)"))
                    completion(.success(modifierRequest))
                case let .failure(error):
                    completion(.failure(error))
            }
        }
    }
}

/// A protocol describing a token authorisation request modifier
@available(iOS 13.0, *)
public protocol UBAsyncURLRequestTokenAuthorization: UBAsyncURLRequestModifier {
    /// Fetches the token and returns it
    ///
    func getToken() async throws -> String
}

@available(iOS 13.0, *)
public extension UBAsyncURLRequestTokenAuthorization {
    /// :nodoc:
    func modifyRequest(_ request: inout UBURLRequest) async throws {
        let token = try await getToken()
        request.setHTTPHeaderField(UBHTTPHeaderField(key: .authorization, value: "Bearer \(token)"))
    }
}
