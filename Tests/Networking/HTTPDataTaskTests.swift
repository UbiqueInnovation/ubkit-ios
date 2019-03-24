//
//  HTTPDataTaskTests.swift
//  UBFoundation iOS Tests
//
//  Created by Joseph El Mallah on 22.03.19.
//

import UBFoundation
import XCTest

class HTTPDataTaskTests: XCTestCase {
    func testStarting() {
//        let ex = expectation(description: "Requesting")
//        let str = "https://www.mocky.io/v2/5185415ba171ea3a00704eed?mocky-delay=2000ms" // "http://ubique.ch"
//        var request = HTTPURLRequest(url: URL(string: str)!)
//        request.setHTTPHeaderField(HTTPHeaderField(key: .accept, value: .json()))
//        request.timeoutInterval = 2
//        let queue = OperationQueue()
//        queue.name = "My queue"
//        let mockSession = DataTaskSessionMock { (request) -> URLSessionDataTaskMock.Configuration in
//            return URLSessionDataTaskMock.Configuration(idleWaitTime: 1, latency: 1, transferDuration: 3, progressUpdateCount: 10, data: "{\"Hello\": \"World\"}".data(using: .utf8)!, response: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil), error: nil)
//        }
//        let dataTask = HTTPDataTask(request: request, taskDescription: "Test task", session: mockSession, callbackQueue: queue)
//        dataTask.addProgressObserver({ _, progress in
//            print(progress)
//        }).addStateTransitionObserver({ old, new in
//            print("\(old) -> \(new)")
//        }).addResponseValidator([
//            HTTPResponseBodyNotEmptyValidator(),
//            HTTPResponseStatusValidator(.ok)
//        ]).addCompletionObserver(decoder: HTTPJSONDecoder<Dictionary<String, String>>(), completionBlock: { result, response in
//            print(result)
//            print(response ?? "Nop")
//            ex.fulfill()
//        }).start()
//
//        waitForExpectations(timeout: 60, handler: nil)
    }
}
