//
//  UBURLRequestModifier.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 01.04.19.
//

import Foundation

/// A request modifier is called before a HTTPDataTask starts and have the chance to change the request.
public protocol UBURLRequestModifier {
    /// Modifies the request before it will start.
    ///
    /// - Parameters:
    ///   - originalRequest: The original request before modification or the most recent request updated by the previous modifiers.
    ///   - completion: The completion handler to be called when the modification are finished.
    func modifyRequest(_ originalRequest: UBURLRequest, completion: @escaping (Result<UBURLRequest, Error>) -> Void)
}
