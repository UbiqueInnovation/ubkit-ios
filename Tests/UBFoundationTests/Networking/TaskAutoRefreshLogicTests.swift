//
//  TaskAutoRefreshLogicTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 04.04.19.
//

import UBFoundation
import UBLocalNetworking
import XCTest

@available(iOS 15.0.0, *)
class TaskAutoRefreshLogicTests: XCTestCase {
    func testNoCacheHeaders() {
        // Load Request with default headers and no cache

        let url = URL(string: "http://no-cache-but-pie.glitch.me")!

        // load request to (not) fill cache

        let dataTask: UBURLDataTask? = UBURLDataTask(url: url)

        let res = expectation(description: "res")
        dataTask?.session
            .reset {
                res.fulfill()
            }
        wait(for: [res], timeout: 10000)

        let ex = expectation(description: "s")
        dataTask?
            .addCompletionHandler(decoder: .passthrough) { _, _, _, _ in

                ex.fulfill()
                dataTask?.cancel()
            }
        dataTask?.start()
        wait(for: [ex], timeout: 10000)

        dataTask?.cancel()  // make sure that cron doesn't trigger

        // load request again

        let dataTask2 = UBURLDataTask(url: url)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler(decoder: .passthrough) { _, _, info, _ in

            if let info {
                XCTAssertFalse(info.cacheHit)
            }
            ex2.fulfill()
        }

        dataTask2.start()
        wait(for: [ex2], timeout: 10000)
    }

    private func startTasks(session: UBURLSession, secondShouldCache: Bool) {
        let url = URL(string: "http://no-cache-but-pie.glitch.me")!

        // load request to (not) fill cache

        let dataTask: UBURLDataTask? = UBURLDataTask(url: url, session: session)

        let res = expectation(description: "res")
        dataTask?.session
            .reset {
                res.fulfill()
            }
        wait(for: [res], timeout: 10000)

        let ex = expectation(description: "s")
        dataTask?
            .addCompletionHandler(decoder: .passthrough) { _, _, _, _ in
                dataTask?.cancel()  // make sure that cron doesn't trigger
                ex.fulfill()
            }
        dataTask?.start()
        wait(for: [ex], timeout: 10000)

        dataTask?.cancel()  // make sure that cron doesn't trigger

        // load request again

        let dataTask2 = UBURLDataTask(url: url, session: session)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler(decoder: .passthrough) { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssert(info!.cacheHit == secondShouldCache)
            ex2.fulfill()
        }

        dataTask2.start()
        wait(for: [ex2], timeout: 10000)
    }

    func testCache304() async throws {
        let url = URL(string: "https://www.ubique.ch")!

        _ = await UBURLDataTask.loadOnce(url: url, decoder: .passthrough)
        let r = await UBURLDataTask.loadOnce(url: url, decoder: .passthrough)
        XCTAssert(r.metadata.info!.cacheHit)
    }

    func testMaxAge0() {
        // Load Request with default headers and max-age=0 directive

        let url = URL(string: "https://httpbin.org/cache/0")!

        // load request to fill cache

        let dataTask = UBURLDataTask(url: url)

        let res = expectation(description: "res")
        dataTask.session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        let ex = expectation(description: "s")
        dataTask.addCompletionHandler(decoder: .passthrough) { _, _, _, _ in

            ex.fulfill()
        }
        dataTask.start()
        wait(for: [ex], timeout: 10000)

        dataTask.cancel()  // make sure that cron doesn't trigger

        // load request again immediately

        let dataTask2 = UBURLDataTask(url: url)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler(decoder: .passthrough) { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssertFalse(info!.cacheHit)

            ex2.fulfill()
        }
        dataTask2.start()
        wait(for: [ex2], timeout: 10000)
    }

    func testCacheHeaderUpdate() {
        // Load Request that changes cached header
        let url = URL(string: "https://example.com/file.json")!

        let initialResponse = try! BasicResponseProvider(
            rule: url.absoluteString, body: "Hello, World!",
            header: BasicResponseProvider.Header(
                statusCode: 200,
                headerFields: [
                    "cache-control": "max-age=5",
                    "etag": "0x8DB4542835F84A7",
                    "Date": UBBaseCachingLogic().dateFormatter.string(from: Date()),
                ]))

        initialResponse.addToLocalServer()

        defer {
            LocalServer.pauseLocalServer()
        }

        let conf = UBURLSessionConfiguration()
        conf.sessionConfiguration.urlCache = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: nil)
        conf.sessionConfiguration.protocolClasses = [LocalServerURLProtocol.self]
        let session = UBURLSession(configuration: conf)

        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        // load request to fill cache
        let dataTask: UBURLDataTask? = UBURLDataTask(url: url, session: session)
        dataTask?.startSynchronous(decoder: .passthrough)
        dataTask?.cancel()

        // immediately load request again, should be cached
        let dataTask2 = UBURLDataTask(url: url, session: session)
        dataTask2.addStateTransitionObserver { _, to, _ in
            XCTAssert(to != .fetching)  // never make the request
        }
        let (_, _, info, _) = dataTask2.startSynchronous(decoder: .passthrough)
        XCTAssert(info != nil)
        XCTAssert(info!.cacheHit)  // in cache

        initialResponse.removeFromLocalServer()

        sleep(6)

        let body = CallbackResponseProvider { re in Data() }
        let headers = CallbackHeaderResponseProvider { re in
            if re.value(forHTTPHeaderField: "If-None-Match") == "0x8DB4542835F84A7" {
                return HTTPURLResponse(url: url, statusCode: 304, httpVersion: nil, headerFields: nil)!
            } else {
                XCTFail()
                return HTTPURLResponse()
            }
        }

        let cachedProv = try! BasicResponseProvider(rule: url.absoluteString, body: body, header: headers)
        cachedProv.addToLocalServer()

        // load request again, now request should return 302
        var dataTask3: UBURLDataTask? = UBURLDataTask(url: url, session: session)
        nonisolated(unsafe) var seenFetching = false
        dataTask3?
            .addStateTransitionObserver { _, to, _ in
                if to == .fetching {
                    seenFetching = true
                }
            }
        let (_, _, info3, _) = dataTask3!.startSynchronous(decoder: .passthrough)

        XCTAssert(info3 != nil)
        XCTAssert(info3!.cacheHit)
        XCTAssert(seenFetching)  // in cache, but request for 302
        dataTask3?.cancel()
        dataTask3 = nil

        // load request again, should be cached again
        let dataTask4 = UBURLDataTask(url: url, session: session)
        let (_, _, info4, _) = dataTask4.startSynchronous(decoder: .passthrough)
        XCTAssert(info4 != nil)
        XCTAssert(info4!.cacheHit)  // in cache again
    }

    func testNoLanguageCaching() {
        // Load Request with Meteo-specific headers to enable cache

        // Ensure that nothing is in cache
        let session = UBURLSession()
        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        let url = URL(string: "https://s3-eu-central-1.amazonaws.com/app-test-static-fra.meteoswiss-app.ch/v1/warnings_with_outlook_with_naturalhazards_de.json")!

        // load request to fill cache
        var request = URLRequest(url: url)
        request.addValue("de", forHTTPHeaderField: "Accept-Language")
        let dataTask: UBURLDataTask? = UBURLDataTask(request: UBURLRequest(request: request), session: session)

        let ex = expectation(description: "s")
        ex.assertForOverFulfill = false
        dataTask?
            .addCompletionHandler(decoder: .passthrough) { _, _, _, _ in
                ex.fulfill()
                dataTask?.cancel()  // make sure that cron doesn't trigger
            }
        dataTask?.start()
        wait(for: [ex], timeout: 10000)

        dataTask?.cancel()  // make sure that cron doesn't trigger

        sleep(5)

        // load request again with different accept language
        var request2 = URLRequest(url: url)
        request2.addValue("fr", forHTTPHeaderField: "Accept-Language")
        let dataTask2 = UBURLDataTask(request: UBURLRequest(request: request2), session: session)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler(decoder: .passthrough) { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssertFalse(info!.cacheHit)

            ex2.fulfill()
        }
        dataTask2.start()
        wait(for: [ex2], timeout: 10000)

        // load request another time, with same accept language
        let dataTask3 = UBURLDataTask(request: UBURLRequest(request: request2), session: session)

        let ex3 = expectation(description: "s2")
        dataTask3.addCompletionHandler(decoder: .passthrough) { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssert(info!.cacheHit)

            ex3.fulfill()
        }
        dataTask3.start()
        wait(for: [ex3], timeout: 10000)
    }

    func testDoubleStart() {
        // Load Request that changes cached header
        let url = URL(string: "https://example.com/file.json")!

        let initialResponse = try! BasicResponseProvider(
            rule: url.absoluteString, body: "Hello, World!",
            header: BasicResponseProvider.Header(
                statusCode: 200,
                headerFields: [
                    "cache-control": "max-age=10000",
                    "etag": "0x8DB4542835F84A7",
                    "Date": UBBaseCachingLogic().dateFormatter.string(from: Date()),
                ]), timing: .init(headerResponseDelay: 1, bodyResponseDelay: 1))

        initialResponse.addToLocalServer()

        defer {
            LocalServer.pauseLocalServer()
        }

        let conf = UBURLSessionConfiguration()
        conf.sessionConfiguration.urlCache = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: nil)
        conf.sessionConfiguration.protocolClasses = [LocalServerURLProtocol.self]
        let session = UBURLSession(configuration: conf)

        // load request to fill cache

        let dataTask = UBURLDataTask(url: url, session: session)

        let ex = expectation(description: "s")
        dataTask.addCompletionHandler(decoder: .passthrough) { _, _, _, _ in

            ex.fulfill()
        }
        dataTask.start()
        wait(for: [ex], timeout: 60)

        // load request again

        let dataTask2 = UBURLDataTask(url: url, session: session)

        let ex2 = expectation(description: "s2")
        ex2.expectedFulfillmentCount = 2
        dataTask2.addCompletionHandler(decoder: .passthrough) { _, _, info, _ in

            XCTAssertNotNil(info)
            XCTAssert(info!.cacheHit)

            ex2.fulfill()
        }
        dataTask2.start()
        dataTask2.start()  // start request again
        wait(for: [ex2], timeout: 60)
    }
}

@available(iOS 15.0.0, *)
private struct CallbackResponseProvider: ResponseProviderBody {
    var bodyCallback: (URLRequest) -> (Data)
    func body(for request: URLRequest) async throws -> Data {
        bodyCallback(request)
    }
}

@available(iOS 15.0.0, *)
private struct CallbackHeaderResponseProvider: ResponseProviderHeader {
    var headerCallback: (URLRequest) -> (HTTPURLResponse)
    func response(for request: URLRequest) async throws -> HTTPURLResponse {
        headerCallback(request)
    }
}
