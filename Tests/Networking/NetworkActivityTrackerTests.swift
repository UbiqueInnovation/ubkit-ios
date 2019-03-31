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
        let request = HTTPURLRequest(url: url)

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: nil, response: nil, error: nil, idleWaitTime: nil, latency: nil, transferDuration: 0.3)
        }
        let mockSession2 = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: nil, response: nil, error: nil, idleWaitTime: nil, latency: nil, transferDuration: 0.7)
        }
        let dataTask = HTTPDataTask(request: request, session: mockSession)
        let dataTask2 = HTTPDataTask(request: request, session: mockSession2)

        let date = Date()
        var sequence: [NetworkActivityTracker.NetworkActivityState] = [.idle, .fetching, .idle]
        let tracker = NetworkActivityTracker()
        tracker.add(dataTask)
        tracker.add(dataTask2)
        tracker.addStateObserver({ state in
            let expectedState = sequence.removeFirst()
            XCTAssertEqual(state, expectedState)
            if sequence.isEmpty {
                XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), 0.75)
                ex.fulfill()
            }
        })
        dataTask.start()
        dataTask2.start()

        waitForExpectations(timeout: 1, handler: nil)
    }
}
