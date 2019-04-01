//
//  HTTPRequestTokenAuthorization.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 01.04.19.
//

import Foundation

/// A protocol describing a token authorisation request modifier
public protocol HTTPRequestTokenAuthorization: HTTPRequestModifier {
    /// Fetches the token and returns it
    ///
    /// - Parameter completion: The completion should be called with success or failure
    func getToken(completion: (Result<String>) -> Void)
}

extension HTTPRequestTokenAuthorization {
    /// :nodoc:
    public func modifyRequest(_ originalRequest: HTTPURLRequest, completion: @escaping (Result<HTTPURLRequest>) -> Void) {
        getToken { result in
            var modifierRequest = originalRequest
            switch result {
            case let .success(token):
                modifierRequest.setHTTPHeaderField(HTTPHeaderField(key: .authorization, value: "Bearer \(token)"))
                completion(.success(modifierRequest))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
