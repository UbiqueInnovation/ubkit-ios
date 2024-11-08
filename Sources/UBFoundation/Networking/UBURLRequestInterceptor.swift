//
//  UBURLRequestInterceptor.swift
//  UBFoundation
//
//  Created by Stefan Mitterrutzner on 12.11.21.
//

import Foundation

/// The UBURLRequestInterceptor holder struct
public struct UBURLInterceptorResult {
    /// the data which should be returned to the completion handler
    let data: Data?
    /// the HTTPURLResponse containing the header fields
    let response: HTTPURLResponse?
    /// optionale error
    let error: Error?
    /// networking task info containing metrics about the network task
    let info: UBNetworkingTaskInfo?

    public init(data: Data?, response: HTTPURLResponse?, error: Error?, info: UBNetworkingTaskInfo?) {
        self.data = data
        self.response = response
        self.error = error
        self.info = info
    }

    /// this initializer creates the HTTPURLResponse internally
    public init(data: Data?, url: URL) {
#if !os(watchOS)
        let info = UBNetworkingTaskInfo(metrics: nil, cacheHit: true, refresh: false)
#else
        let info = UBNetworkingTaskInfo(cacheHit: true, refresh: false)
#endif
        self.init(data: data,
                  response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2.0", headerFields: [:]),
                  error: nil,
                  info: info)
    }
}

/// A request interceptor is called before a HTTPDataTask starts. It can be used to intercept the networ call and directly return a Response
public protocol UBURLRequestInterceptor: Sendable {
    /// Intercepts the request before it will start.
    ///
    /// - Parameters:
    ///   - request: The request which would be executed by the URLSession
    ///   - completion: The completion handler to be called with a InterceptorResult
    func interceptRequest(_ request: UBURLRequest, completion: @escaping @Sendable (UBURLInterceptorResult?) -> Void)
}
