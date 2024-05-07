//
//  NetworkActivityTrackerTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 31.03.19.
//

import UBFoundation
import XCTest

class NetworkActivityTrackerTests: XCTestCase {
    let url = URL(string: "http://ubique.ch")!

    func testGlobalStateOneRunningOneDone() {
        let ex = expectation(description: "Network activity")
        let request = UBURLRequest(url: url)

        let mockSession = DataTaskSessionMock { _ -> URLSessionDataTaskMock.Configuration in
            URLSessionDataTaskMock.Configuration(data: nil, response: nil, error: nil, idleWaitTime: nil, latency: nil, transferDuration: 0.3)
        }
        let mockSession2 = DataTaskSessionMock { _ -> URLSessionDataTaskMock.Configuration in
            URLSessionDataTaskMock.Configuration(data: nil, response: nil, error: nil, idleWaitTime: nil, latency: nil, transferDuration: 0.7)
        }
        let dataTask = UBURLDataTask(request: request, session: mockSession)
        let dataTask2 = UBURLDataTask(request: request, session: mockSession2)

        let date = Date()
        var sequence: [UBNetworkActivityTracker.NetworkActivityState] = [.idle, .fetching, .idle]
        let tracker = UBNetworkActivityTracker()
        tracker.add(dataTask)
        tracker.add(dataTask2)
        tracker.addStateObserver { state in
            let expectedState = sequence.removeFirst()
            XCTAssertEqual(state, expectedState)
            if sequence.isEmpty {
                XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), 0.75)
                ex.fulfill()
            }
        }
        dataTask.start()
        dataTask2.start()

        waitForExpectations(timeout: 30, handler: nil)
    }
}
