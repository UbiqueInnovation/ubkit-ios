//
//  TaskAutoRefreshLogicTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 04.04.19.
//

import UBFoundation
import UBLocalNetworking
import XCTest

class TaskAutoRefreshLogicTests: XCTestCase {
    func testCaching() {
        // Load Request with Meteo-specific headers to enable cache

        let url = URL(string: "https://s3-eu-central-1.amazonaws.com/app-test-static-fra.meteoswiss-app.ch/v1/warnings_with_outlook_with_naturalhazards_de.json")!

        let cache = MeteoAutoRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        let c = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: "meteo")
        c.removeAllCachedResponses()
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        // load request to fill cache

        var dataTask: UBURLDataTask? = UBURLDataTask(url: url, session: session)

        let ex = expectation(description: "s")
        ex.assertForOverFulfill = false
        dataTask?.addCompletionHandler { _, _, _, _ in
            ex.fulfill()
            dataTask?.cancel() // make sure that cron doesn't trigger
            dataTask = nil
        }
        dataTask?.start()
        wait(for: [ex], timeout: 10000)

        dataTask?.cancel() // make sure that cron doesn't trigger
        dataTask = nil

        sleep(5)

        // load request again

        let dataTask2 = UBURLDataTask(url: url, session: session)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssert(info!.cacheHit)

            ex2.fulfill()
        }
        dataTask2.start()
        wait(for: [ex2], timeout: 10000)
    }

    func testCachingWithoutCacheControl() {
        // Request with cron headers should cache even if no default cache control is set

        let url = URL(string: "https://s3-eu-central-1.amazonaws.com/app-test-static-fra.meteoswiss-app.ch/v1/animation_overview.json")!

        let cache = MeteoAutoRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        let c = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: "meteo")
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        // load request to fill cache

        let dataTask = UBURLDataTask(url: url, session: session)

        let ex = expectation(description: "s")
        dataTask.addCompletionHandler { _, _, _, _ in

            ex.fulfill()
        }
        dataTask.start()
        wait(for: [ex], timeout: 10000)

        // load request again

        let dataTask2 = UBURLDataTask(url: url, session: session)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssert(info!.cacheHit)

            ex2.fulfill()
        }
        dataTask2.start()
        wait(for: [ex2], timeout: 10000)
    }

    func testRegaCaching() {
        // Load Request with Meteo-specific headers to enable cache

        let url = URL(string: "https://p-aps-regaws.azurewebsites.net/v1/webcam_overview.json")!

        let cache = RegaAutoRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        let c = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: "meteo")
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        // load request to fill cache

        let dataTask = UBURLDataTask(url: url, session: session)

        let ex = expectation(description: "s")
        dataTask.addCompletionHandler { _, _, _, _ in

            ex.fulfill()
        }
        dataTask.start()
        wait(for: [ex], timeout: 10000)

        // load request again

        let dataTask2 = UBURLDataTask(url: url, session: session)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssert(info!.cacheHit)

            ex2.fulfill()
        }

        let ex3 = expectation(description: "s3")
        dataTask2.addCompletionHandler { _, _, _, _ in

            ex3.fulfill()
        }

        dataTask2.start()
        wait(for: [ex2, ex3], timeout: 10000)
    }

    func testNoCacheHeaders() {
        // Load Request with default headers and no cache

        let url = URL(string: "http://no-cache-but-pie.glitch.me")!

        // load request to (not) fill cache

        var dataTask: UBURLDataTask? = UBURLDataTask(url: url)

        let res = expectation(description: "res")
        dataTask?.session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        let ex = expectation(description: "s")
        dataTask?.addCompletionHandler { _, _, _, _ in

            ex.fulfill()
            dataTask?.cancel()
            dataTask = nil
        }
        dataTask?.start()
        wait(for: [ex], timeout: 10000)

        dataTask?.cancel() // make sure that cron doesn't trigger
        dataTask = nil

        // load request again

        let dataTask2 = UBURLDataTask(url: url)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssertFalse(info!.cacheHit)
            ex2.fulfill()
        }

        dataTask2.start()
        wait(for: [ex2], timeout: 10000)
    }

    func testCacheModifier() {
        startTasks(session: Networking.sharedSession, secondShouldCache: false)

        let cache = SwisstopoMapAutorefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        let session = UBURLSession(configuration: conf)

        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        startTasks(session: session, secondShouldCache: true)
    }

    private func startTasks(session: UBURLSession, secondShouldCache: Bool) {
        let url = URL(string: "http://no-cache-but-pie.glitch.me")!

        // load request to (not) fill cache

        var dataTask: UBURLDataTask? = UBURLDataTask(url: url, session: session)

        let res = expectation(description: "res")
        dataTask?.session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        let ex = expectation(description: "s")
        dataTask?.addCompletionHandler { _, _, _, _ in
            dataTask?.cancel() // make sure that cron doesn't trigger
            dataTask = nil
            ex.fulfill()
        }
        dataTask?.start()
        wait(for: [ex], timeout: 10000)

        dataTask?.cancel() // make sure that cron doesn't trigger
        dataTask = nil

        // load request again

        let dataTask2 = UBURLDataTask(url: url, session: session)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssert(info!.cacheHit == secondShouldCache)
            ex2.fulfill()
        }

        dataTask2.start()
        wait(for: [ex2], timeout: 10000)
    }

    func testMaxAge0() {
        // Load Request with default headers and max-age=0 directive

        let url = URL(string: "http://worldtimeapi.org/api/timezone/Europe/Zurich.txt")!

        // load request to fill cache

        let dataTask = UBURLDataTask(url: url)

        let res = expectation(description: "res")
        dataTask.session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        let ex = expectation(description: "s")
        dataTask.addCompletionHandler { _, _, _, _ in

            ex.fulfill()
        }
        dataTask.start()
        wait(for: [ex], timeout: 10000)

        dataTask.cancel() // make sure that cron doesn't trigger

        // load request again immediately

        let dataTask2 = UBURLDataTask(url: url)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssertFalse(info!.cacheHit)

            ex2.fulfill()
        }
        dataTask2.start()
        wait(for: [ex2], timeout: 10000)
    }

    func testAutoRefresh() {
        // Load Request with default headers and no cache

        let url = URL(string: "https://s3-eu-central-1.amazonaws.com/app-test-static-fra.meteoswiss-app.ch/v1/warnings_with_outlook_with_naturalhazards_de.json")!

        // load request and wait for two responses

        let cache = MeteoAutoRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        let c = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: "meteo")
        c.removeAllCachedResponses()
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        let dataTask = UBURLDataTask(url: url, session: session)

        let ex1 = expectation(description: "s")
        let ex2 = expectation(description: "s2")

        dataTask.addCompletionHandler { _, _, info, _ in

            XCTAssert(info != nil)

            if info!.refresh {
                ex1.fulfill()
            } else {
                ex2.fulfill()
            }
        }
        dataTask.start()
        wait(for: [ex1, ex2], timeout: 10000)
    }

    @available(iOS 13.0, *)
    func testCacheHeaderUpdate() {
        // Load Request that changes cached header
        let url = URL(string: "https://example.com/file.json")!

        let initialResponse = try! BasicResponseProvider(rule: url.absoluteString, body: "Hello, World!", header: BasicResponseProvider.Header(statusCode: 200, headerFields: [
            "cache-control": "max-age=10",
            "etag": "0x8DB4542835F84A7",
            "Date": UBBaseCachingLogic().dateFormatter.string(from: Date()),
        ]))

        initialResponse.addToLocalServer()

        defer {
            LocalServer.pauseLocalServer()
        }

        let cache = SwisstopoVectorRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        conf.sessionConfiguration.urlCache = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: nil)
        conf.sessionConfiguration.protocolClasses = [LocalServerURLProtocol.self]
        let session = UBURLSession(configuration: conf)

        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        // load request to fill cache
        var dataTask: UBURLDataTask? = UBURLDataTask(url: url, session: session)
        dataTask?.startSynchronous()
        dataTask?.cancel()

        // immediately load request again, should be cached
        let dataTask2 = UBURLDataTask(url: url, session: session)
        dataTask2.addStateTransitionObserver { _, to, _ in
            XCTAssert(to != .fetching) // never make the request
        }
        let (_, _, info, _) = dataTask2.startSynchronous()
        XCTAssert(info != nil)
        XCTAssert(info!.cacheHit) // in cache

        initialResponse.removeFromLocalServer()
        // Cache should only be valid for 60 seconds
        sleep(10)

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
        var seenFetching = false
        dataTask3?.addStateTransitionObserver { _, to, _ in
            if to == .fetching {
                seenFetching = true
            }
        }
        let (_, _, info3, _) = dataTask3!.startSynchronous()

        XCTAssert(info3 != nil)
        XCTAssert(info3!.cacheHit)
        XCTAssert(seenFetching) // in cache, but request for 302
        dataTask3?.cancel()
        dataTask3 = nil

        // load request again, should be cached again
        let dataTask4 = UBURLDataTask(url: url, session: session)
        let (_, _, info4, _) = dataTask4.startSynchronous()
        XCTAssert(info4 != nil)
        XCTAssert(info4!.cacheHit) // in cache again
    }

    func testEmptyCache() {
        // Ensure that request with empty body is cached too

        let url = URL(string: "https://dev-static.swisstopo-app.ch/v10/stations/22/417/158.pbf")!

        let cache = SwisstopoVectorRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        let c = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: "meteo")
        c.removeAllCachedResponses()
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        // load request to fill cache

        let dataTask = UBURLDataTask(url: url, session: session)

        dataTask.startSynchronous()

        // load request again

        let dataTask2 = UBURLDataTask(url: url, session: session)
        dataTask2.addStateTransitionObserver { _, to, _ in
            XCTAssert(to != .fetching) // never make the request
        }
        let (_, _, info, _) = dataTask2.startSynchronous()

        XCTAssert(info != nil)
        XCTAssert(info!.cacheHit)
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
        var dataTask: UBURLDataTask? = UBURLDataTask(request: UBURLRequest(request: request), session: session)

        let ex = expectation(description: "s")
        ex.assertForOverFulfill = false
        dataTask?.addCompletionHandler { _, _, _, _ in
            ex.fulfill()
            dataTask?.cancel() // make sure that cron doesn't trigger
            dataTask = nil
        }
        dataTask?.start()
        wait(for: [ex], timeout: 10000)

        dataTask?.cancel() // make sure that cron doesn't trigger
        dataTask = nil

        sleep(5)

        // load request again with different accept language
        var request2 = URLRequest(url: url)
        request2.addValue("fr", forHTTPHeaderField: "Accept-Language")
        let dataTask2 = UBURLDataTask(request: UBURLRequest(request: request2), session: session)

        let ex2 = expectation(description: "s2")
        dataTask2.addCompletionHandler { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssertFalse(info!.cacheHit)

            ex2.fulfill()
        }
        dataTask2.start()
        wait(for: [ex2], timeout: 10000)

        // load request another time, with same accept language
        let dataTask3 = UBURLDataTask(request: UBURLRequest(request: request2), session: session)

        let ex3 = expectation(description: "s2")
        dataTask3.addCompletionHandler { _, _, info, _ in

            XCTAssert(info != nil)
            XCTAssert(info!.cacheHit)

            ex3.fulfill()
        }
        dataTask3.start()
        wait(for: [ex3], timeout: 10000)
    }
}

private class MeteoAutoRefreshCacheLogic: UBAutoRefreshCacheLogic {
    // scale relative time for faster unit test
    override func cachedResponseNextRefreshDate(_ allHeaderFields: [AnyHashable: Any], metrics: URLSessionTaskMetrics?) -> Date? {
        if let date = super.cachedResponseNextRefreshDate(allHeaderFields, metrics: metrics) {
            return Date(timeIntervalSinceNow: date.timeIntervalSinceNow * 0.01)
        } else {
            return nil
        }
    }
}

class RegaAutoRefreshCacheLogic: UBAutoRefreshCacheLogic {
    // scale relative time for faster unit test
    override func cachedResponseNextRefreshDate(_ allHeaderFields: [AnyHashable: Any], metrics: URLSessionTaskMetrics?) -> Date? {
        if let date = super.cachedResponseNextRefreshDate(allHeaderFields, metrics: metrics) {
            return Date(timeIntervalSinceNow: date.timeIntervalSinceNow * 0.01)
        } else {
            return nil
        }
    }
}

class SwisstopoVectorRefreshCacheLogic: UBAutoRefreshCacheLogic {
    // scale relative time for faster unit test
    override func cachedResponseNextRefreshDate(_ allHeaderFields: [AnyHashable: Any], metrics: URLSessionTaskMetrics?) -> Date? {
        if let date = super.cachedResponseNextRefreshDate(allHeaderFields, metrics: metrics) {
            return Date(timeIntervalSinceNow: date.timeIntervalSinceNow * 0.1)
        } else {
            return nil
        }
    }
}

class SwisstopoMapAutorefreshCacheLogic: UBAutoRefreshCacheLogic {
    override func shouldWriteToCache(allowed _: Bool, data _: Data?, response _: HTTPURLResponse) -> Bool {
        true
    }

    override func modifyCacheResult(proposed _: UBCacheResult, possible: UBCacheResult, reason _: UBBaseCachingLogic.CacheDecisionReason) -> UBCacheResult {
        possible
    }
}

private struct CallbackResponseProvider: ResponseProviderBody {
    var bodyCallback: (URLRequest) -> (Data)
    func body(for request: URLRequest) async throws -> Data {
        bodyCallback(request)
    }
}

private struct CallbackHeaderResponseProvider: ResponseProviderHeader {
    var headerCallback: (URLRequest) -> (HTTPURLResponse)
    func response(for request: URLRequest) async throws -> HTTPURLResponse {
        headerCallback(request)
    }
}
