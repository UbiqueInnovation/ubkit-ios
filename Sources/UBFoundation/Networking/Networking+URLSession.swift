//
//  Networking+URLSession.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 02.04.19.
//

import Foundation

// URLSession conforms to URLSessionProtocol
extension URLSession: UBDataTaskURLSession {
    /// :nodoc:
    public func dataTask(with request: UBURLRequest, owner: UBURLDataTask) -> URLSessionDataTask? {
        dataTask(with: request.getRequest(), completionHandler: { [weak owner] data, response, baseError in
            guard let owner = owner else {
                return
            }
            var error = baseError
            if error == nil, (response is HTTPURLResponse) == false {
                error = UBInternalNetworkingError.notHTTPResponse
            }

            if let r = response as? HTTPURLResponse {
                do {
                    try owner.validate(response: r)
                    owner.dataTaskCompleted(data: data, response: r, error: error, info: nil)
                } catch {
                    owner.dataTaskCompleted(data: data, response: r, error: error, info: nil)
                }
            } else {
                owner.dataTaskCompleted(data: data, response: nil, error: error, info: nil)
            }

        })
    }
}
