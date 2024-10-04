//
//  HTTPRequestInterceptorsTests.swift
//  UBFoundation
//
//  Created by Stefan Mitterrutzner on 15.11.21.
//

import UBFoundation
import XCTest

class HTTPRequestInterceptorsTests: XCTestCase {
    let request = UBURLRequest(url: URL(string: "http://ubique.ch")!)

    func testEmptyInterceptor() {
        let ex1 = expectation(description: "Request")
        let expectedResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        let mockSession = DataTaskSessionMock { _ -> URLSessionDataTaskMock.Configuration in
            URLSessionDataTaskMock.Configuration(data: nil, response: expectedResponse, error: nil)
        }
        let dataTask = UBURLDataTask(request: request, session: mockSession)
        dataTask.setRequestInterceptor(EmptyInterceptor())
        dataTask.addCompletionHandler(decoder: .passthrough) { result, response, _, _ in
            switch result {
                case .success:
                    XCTAssertEqual(response?.statusCode, expectedResponse?.statusCode)
                case .failure:
                    XCTFail("Should have returned success with empty")
            }
            ex1.fulfill()
        }
        dataTask.start()
        wait(for: [ex1], timeout: 30)
    }

    func testInterceptor() {
        let ex1 = expectation(description: "Request")
        let expectedResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        let mockSession = DataTaskSessionMock { _ -> URLSessionDataTaskMock.Configuration in
            URLSessionDataTaskMock.Configuration(data: nil, response: expectedResponse, error: nil)
        }
        let dataTask = UBURLDataTask(request: request, session: mockSession)
        dataTask.setRequestInterceptor(Interceptor())
        dataTask.addCompletionHandler(decoder: .passthrough) { result, response, _, _ in
            switch result {
                case let .success(data):
                    XCTAssertEqual(response?.statusCode, 401)
                    XCTAssertEqual(data, Data(repeating: 1, count: 15))
                case .failure:
                    XCTFail("Should have returned success with empty")
            }
            ex1.fulfill()
        }
        dataTask.start()
        wait(for: [ex1], timeout: 30)
    }
}

private struct EmptyInterceptor: UBURLRequestInterceptor {
    func interceptRequest(_: UBURLRequest, completion: @escaping @Sendable (UBURLInterceptorResult?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            completion(nil)
        }
    }
}

private struct Interceptor: UBURLRequestInterceptor {
    func interceptRequest(_ request: UBURLRequest, completion: @escaping @Sendable (UBURLInterceptorResult?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: "1.1", headerFields: nil)
            completion(UBURLInterceptorResult(data: Data(repeating: 1, count: 15), response: response, error: nil, info: nil))
        }
    }
}
