//
//  DataTaskSessionMock.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 22.03.19.
//

import Foundation
@testable import UBFoundation

class DataTaskSessionMock: UBDataTaskURLSession {
    private var _allTasks: [URLSessionTask] = []
    var dataTaskConfigurationBlock: (UBURLRequest) -> URLSessionDataTaskMock.Configuration

    init(_ block: @escaping (UBURLRequest) -> URLSessionDataTaskMock.Configuration) {
        dataTaskConfigurationBlock = block
    }

    required init(configuration _: URLSessionConfiguration) {
        fatalError("Not emplemented")
    }

    required init(configuration _: URLSessionConfiguration, delegate _: URLSessionDelegate?, delegateQueue _: OperationQueue?) {
        fatalError("Not emplemented")
    }

    func dataTask(with request: UBURLRequest, owner: UBURLDataTask) -> URLSessionDataTask? {
        let task = URLSessionDataTaskMock(config: dataTaskConfigurationBlock(request), timeoutInterval: request.timeoutInterval) { [weak owner] data, response, baseError in
            guard let owner = owner else {
                return
            }
            var error = baseError
            if error == nil, (response is HTTPURLResponse) == false {
                error = UBNetworkingError.notHTTPResponse
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
        }
        _allTasks.append(task)
        return task
    }

    func finishTasksAndInvalidate() {
        fatalError("Not emplemented")
    }

    func invalidateAndCancel() {
        fatalError("Not emplemented")
    }

    func reset(completionHandler _: @escaping () -> Void) {
        fatalError("Not emplemented")
    }
}
