//
//  HTTPDataTaskTests.swift
//  UBFoundation iOS Tests
//
//  Created by Joseph El Mallah on 22.03.19.
//

import UBFoundation
import XCTest

class HTTPDataTaskTests: XCTestCase {
    let url = URL(string: "http://ubique.ch")!

    func testCompletionFailure() {
        let ex1 = expectation(description: "Request")

        let request = HTTPURLRequest(url: url)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: nil, response: nil, error: error)
        }
        let dataTask = HTTPDataTask(request: request, session: mockSession)
        dataTask.addCompletionHandler { result, _ in
            switch result {
            case .failure:
                break
            case .success:
                XCTFail("Should have failed")
            }
            ex1.fulfill()
        }.start()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCompletionNoData() {
        let ex1 = expectation(description: "Request")
        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: nil, response: expectedResponse, error: nil)
        }
        let dataTask = HTTPDataTask(request: request, session: mockSession)
        dataTask.addCompletionHandler { result, _ in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Should have returned success with empty")
            }
            ex1.fulfill()
        }.start()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCompletionRequestModifiers() {
        let ex1 = expectation(description: "Request")
        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        let mockSession = DataTaskSessionMock { (request) -> URLSessionDataTaskMock.Configuration in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic bG9naW46cGFzc3dvcmQ=")
            return URLSessionDataTaskMock.Configuration(data: nil, response: expectedResponse, error: nil)
        }
        let dataTask = HTTPDataTask(request: request, session: mockSession)
        dataTask.addRequestModifier(HTTPRequestBasicAuthorization(login: "login", password: "password"))
        dataTask.addCompletionHandler { _, _ in
            ex1.fulfill()
        }.start()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCompletionJSONData() {
        let ex1 = expectation(description: "Request")
        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let expectedData = "{\"value\":\"A\"}".data(using: .utf8)

        struct TestStruct: Codable {
            let value: String
        }

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: expectedData, response: expectedResponse, error: nil)
        }
        let dataTask = HTTPDataTask(request: request, session: mockSession)
        dataTask.addCompletionHandler(decoder: HTTPJSONDecoder<TestStruct>()) { result, _, _ in
            switch result {
            case let .success(test):
                XCTAssertEqual(test.value, "A")
            default:
                XCTFail("Should have returned success with empty")
            }
            ex1.fulfill()
        }.start()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCompletion() {
        let ex1 = expectation(description: "Request")
        let ex2 = expectation(description: "Request")
        let ex3 = expectation(description: "Request")

        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let expectedData = "Hello".data(using: .utf16)!

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: expectedData, response: expectedResponse, error: nil)
        }

        let dataTask = HTTPDataTask(request: request, session: mockSession)
        dataTask.addCompletionHandler { result, response in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Should have returned data")
            }
            XCTAssertEqual(response?.statusCode, expectedResponse?.statusCode)
            ex1.fulfill()
        }.addCompletionHandler(decoder: HTTPStringDecoder(), completionHandler: { result, _, _ in
            switch result {
            case .failure:
                break
            default:
                XCTFail("Should have failed parsing")
            }
            ex2.fulfill()
        }).addCompletionHandler(decoder: HTTPStringDecoder(encoding: .utf16), completionHandler: { result, _, _ in
            switch result {
            case let .success(data):
                XCTAssertEqual(data, "Hello")
            default:
                XCTFail("Should have returned a string")
            }
            ex3.fulfill()
        }).start()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testValidation() {
        let ex1 = expectation(description: "Request")
        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: nil, response: expectedResponse, error: nil)
        }
        let dataTask = HTTPDataTask(request: request, session: mockSession)
        dataTask.addCompletionHandler { result, _ in
            switch result {
            case let .success(data):
                XCTAssertNil(data)
            case .failure:
                XCTFail()
            }
            ex1.fulfill()
        }.start()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testValidationBlock() {
        let ex1 = expectation(description: "Request")
        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: nil, response: expectedResponse, error: nil)
        }
        let dataTask = HTTPDataTask(request: request, session: mockSession)
        dataTask.addResponseValidator { _ in
            throw NetworkingError.responseMIMETypeValidationFailed
        }
        dataTask.addCompletionHandler { result, _ in
            switch result {
            case let .failure(error):
                XCTAssertEqual(error as? NetworkingError, NetworkingError.responseMIMETypeValidationFailed)
            case .success:
                XCTFail("Should have returned success with empty")
            }
            ex1.fulfill()
        }.start()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testValidationList() {
        let ex1 = expectation(description: "Request")
        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: "1".data(using: .utf8)!, response: expectedResponse, error: nil)
        }
        let dataTask = HTTPDataTask(request: request, session: mockSession)
        dataTask.addResponseValidator([
            HTTPResponseStatusValidator(.success),
            HTTPResponseContentTypeValidator(expectedMIMEType: .png)
        ])
        dataTask.addCompletionHandler { result, _ in
            switch result {
            case let .failure(error):
                XCTAssertEqual(error as? NetworkingError, NetworkingError.responseMIMETypeValidationFailed)
            case .success:
                XCTFail("Should have returned success with empty")
            }
            ex1.fulfill()
        }.start()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testStateChange() {
        let ex1 = expectation(description: "Request")
        let ex2 = expectation(description: "Request")
        let ex3 = expectation(description: "Request")
        let ex4 = expectation(description: "Request")

        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: "1".data(using: .utf8)!, response: expectedResponse, error: nil)
        }
        let dataTask = HTTPDataTask(request: request, session: mockSession)
        XCTAssertEqual(dataTask.state, .initial)
        dataTask.addStateTransitionObserver { _, new, _ in
            switch new {
            case .waitingExecution:
                ex1.fulfill()
            case .fetching:
                ex2.fulfill()
            case .parsing:
                ex3.fulfill()
            case .finished:
                ex4.fulfill()
            default:
                break
            }
        }.start()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgress() {
        let ex1 = expectation(description: "Request")

        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)

        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: "1".data(using: .utf8)!, response: expectedResponse, error: nil)
        }

        let dataTask = HTTPDataTask(request: request, session: mockSession)
        XCTAssertEqual(dataTask.progress.fractionCompleted, 0)

        var progressTracker: Double = -1
        dataTask.addProgressObserver { _, progress in
            XCTAssertLessThan(progressTracker, progress)
            progressTracker = progress
            if progress > 0.99 {
                ex1.fulfill()
            }
        }
        dataTask.start()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCancelBeforeTaskExecute() {
        let ex1 = expectation(description: "Request")
        let ex2 = expectation(description: "Request")

        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: nil, response: expectedResponse, error: nil, idleWaitTime: 0.5, latency: nil, transferDuration: 2, progressUpdateCount: 5)
        }

        let dataTask = HTTPDataTask(request: request, session: mockSession)
        XCTAssertEqual(dataTask.state, .initial)
        XCTAssertEqual(dataTask.progress.fractionCompleted, 0)

        dataTask.addStateTransitionObserver { _, new, _ in
            switch new {
            case .waitingExecution:
                ex1.fulfill()
            case .cancelled:
                ex2.fulfill()
            default:
                XCTFail()
            }
        }

        dataTask.addResponseValidator { _ in
            XCTFail()
        }

        dataTask.addCompletionHandler { result, _ in
            switch result {
            case let .failure(error):
                XCTAssertEqual((error as NSError).code, NSURLErrorCancelled)
            case .success:
                XCTFail()
            }
        }

        dataTask.start()

        let t = Timer(timeInterval: 0.3, repeats: false) { _ in
            dataTask.cancel()
        }
        RunLoop.main.add(t, forMode: .common)

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(dataTask.state, .cancelled)
        XCTAssertEqual(dataTask.progress.fractionCompleted, 0)
    }

    func testCancelWhileFetching() {
        let exProg = expectation(description: "Request")
        exProg.assertForOverFulfill = false
        let ex1 = expectation(description: "Request")
        let ex2 = expectation(description: "Request")
        let ex3 = expectation(description: "Request")

        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: nil, response: expectedResponse, error: nil, idleWaitTime: nil, latency: nil, transferDuration: 0.5, progressUpdateCount: 10)
        }

        let dataTask = HTTPDataTask(request: request, session: mockSession)
        XCTAssertEqual(dataTask.state, .initial)
        XCTAssertEqual(dataTask.progress.fractionCompleted, 0)

        dataTask.addStateTransitionObserver { _, new, _ in
            switch new {
            case .waitingExecution:
                ex1.fulfill()
            case .fetching:
                ex2.fulfill()
            case .cancelled:
                ex3.fulfill()
            default:
                XCTFail()
            }
        }

        dataTask.addResponseValidator { _ in
            XCTFail()
        }

        var pTracker: Double = -1
        dataTask.addProgressObserver { _, progress in
            XCTAssertLessThan(pTracker, progress)
            pTracker = progress
            if pTracker > 0.3 {
                exProg.fulfill()
            }
        }

        dataTask.addCompletionHandler { result, _ in
            switch result {
            case let .failure(error):
                XCTAssertEqual((error as NSError).code, NSURLErrorCancelled)
            case .success:
                XCTFail()
            }
        }

        dataTask.start()

        let t = Timer(timeInterval: 0.25, repeats: false) { _ in
            // This should trigger also the cancelation of the task
            dataTask.request = HTTPURLRequest(url: self.url)
        }
        RunLoop.main.add(t, forMode: .common)

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(dataTask.state, .cancelled)
        XCTAssertEqual(dataTask.progress.fractionCompleted, 0)
    }

    func testDeallocation() {
        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: nil, response: expectedResponse, error: nil, idleWaitTime: nil, latency: nil, transferDuration: 0.5, progressUpdateCount: 10)
        }

        var dataTask: HTTPDataTask? = HTTPDataTask(request: request, session: mockSession)
        weak var ref = dataTask

        dataTask!.addCompletionHandler { _, _ in
            XCTFail()
        }

        dataTask!.start()
        let ex = expectation(description: "Waiting")
        let t = Timer(timeInterval: 0.25, repeats: false) { _ in
            XCTAssertNotEqual(dataTask!.state, .initial)
            dataTask = nil
            XCTAssertNil(ref)
            let m = Timer(timeInterval: 0.5, repeats: false, block: { _ in
                ex.fulfill()
            })
            RunLoop.main.add(m, forMode: .common)
        }
        RunLoop.main.add(t, forMode: .common)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testOperatinoQueue() {
        let ex1 = expectation(description: "Request")
        ex1.assertForOverFulfill = false
        let ex2 = expectation(description: "Request")
        ex2.assertForOverFulfill = false
        let ex3 = expectation(description: "Request")
        let ex4 = expectation(description: "Request")
        let ex5 = expectation(description: "Request")

        let request = HTTPURLRequest(url: url)
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let mockSession = DataTaskSessionMock { (_) -> URLSessionDataTaskMock.Configuration in
            return URLSessionDataTaskMock.Configuration(data: "1".data(using: .utf8)!, response: expectedResponse, error: nil, idleWaitTime: nil, latency: nil, transferDuration: 0.2, progressUpdateCount: 10)
        }

        let queue = OperationQueue()
        queue.name = "Test"

        let dataTask = HTTPDataTask(request: request, taskDescription: "Hello", session: mockSession, callbackQueue: queue)

        dataTask.addStateTransitionObserver { _, _, _ in
            XCTAssertEqual(queue, OperationQueue.current!)
            ex1.fulfill()
        }

        dataTask.addProgressObserver { _, _ in
            XCTAssertEqual(queue, OperationQueue.current!)
            ex2.fulfill()
        }

        dataTask.addResponseValidator { _ in
            XCTAssertNotEqual(queue, OperationQueue.current)
            XCTAssertNotEqual(queue, OperationQueue.main)
            ex3.fulfill()
        }

        let decoder = HTTPDataDecoder { (data, _) -> Data in
            XCTAssertNotEqual(queue, OperationQueue.current)
            XCTAssertNotEqual(queue, OperationQueue.main)
            ex4.fulfill()
            return data
        }

        dataTask.addCompletionHandler(decoder: decoder) { _, _, _ in
            XCTAssertEqual(queue, OperationQueue.current!)
            ex5.fulfill()
        }

        dataTask.start()

        waitForExpectations(timeout: 1, handler: nil)
    }
}
