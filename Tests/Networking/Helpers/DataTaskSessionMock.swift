//
//  DataTaskSessionMock.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 22.03.19.
//

import Foundation
import UBFoundation

class DataTaskSessionMock: URLSessionProtocol {
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

    func dataTask(with request: UBURLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSessionDataTaskMock(config: dataTaskConfigurationBlock(request), timeoutInterval: request.timeoutInterval, completionHandler: completionHandler)
        _allTasks.append(task)
        return task
    }

    func downloadTask(with _: UBURLRequest, completionHandler _: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fatalError("Not emplemented")
    }

    func downloadTask(withResumeData _: Data, completionHandler _: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fatalError("Not emplemented")
    }

    func uploadTask(with _: UBURLRequest, from _: Data?, completionHandler _: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        fatalError("Not emplemented")
    }

    func uploadTask(with _: UBURLRequest, fromFile _: URL, completionHandler _: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        fatalError("Not emplemented")
    }

    func getAllTasks(completionHandler: @escaping ([URLSessionTask]) -> Void) {
        completionHandler(_allTasks)
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
