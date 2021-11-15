//
//  UBURLRequestInterceptor.swift
//  UBFoundation
//
//  Created by Stefan Mitterrutzner on 12.11.21.
//

import Foundation

/// A request interceptor is called before a HTTPDataTask starts. It can be used to intercept the networ call and directly return a Response
public protocol UBURLRequestInterceptor {

    typealias InterceptorResult = (data: Data?, response: HTTPURLResponse?, error: Error?, info: UBNetworkingTaskInfo?)

    /// Intercepts the request before it will start.
    ///
    /// - Parameters:
    ///   - request: The request which would be executed by the URLSession
    ///   - completion: The completion handler to be called with a InterceptorResult
    func interceptRequest(_ request: UBURLRequest, completion: @escaping (InterceptorResult?) -> Void)
}
