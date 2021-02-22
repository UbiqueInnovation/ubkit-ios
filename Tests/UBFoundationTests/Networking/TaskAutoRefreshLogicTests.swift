//
//  TaskAutoRefreshLogicTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 04.04.19.
//

import UBFoundation
import XCTest

class TaskAutoRefreshLogicTests: XCTestCase {
    let c = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: "meteo")

    func testCaching() {
        // Load Request with Meteo-specific headers to enable cache

        let url = URL(string: "https://s3-eu-central-1.amazonaws.com/app-test-static-fra.meteoswiss-app.ch/v1/warnings_with_outlook_with_naturalhazards_de.json")!

        let cache = MeteoAutoRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

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

    func testCachingWithoutCacheControl() {
        // Request with cron headers should cache even if no default cache control is set

        let url = URL(string: "https://s3-eu-central-1.amazonaws.com/app-test-static-fra.meteoswiss-app.ch/v1/animation_overview.json")!

        let cache = MeteoAutoRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

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
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

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

        let dataTask = UBURLDataTask(url: url)

        let ex = expectation(description: "s")
        dataTask.addCompletionHandler { _, _, _, _ in

            ex.fulfill()
        }
        dataTask.start()
        wait(for: [ex], timeout: 10000)

        dataTask.cancel() // make sure that cron doesn't trigger

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

        startTasks(session: session, secondShouldCache: true)
    }

    private func startTasks(session: UBURLSession, secondShouldCache: Bool) {
        let url = URL(string: "http://no-cache-but-pie.glitch.me")!

        // load request to (not) fill cache

        let dataTask = UBURLDataTask(url: url, session: session)

        let ex = expectation(description: "s")
        dataTask.addCompletionHandler { _, _, _, _ in

            ex.fulfill()
        }
        dataTask.start()
        wait(for: [ex], timeout: 10000)

        dataTask.cancel() // make sure that cron doesn't trigger

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
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

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

    func testCacheHeaderUpdate() {
        // Load Request that changes cached header

        let url = URL(string: "https://dev-static.swisstopo-app.ch/v10/stations/22/412/155.pbf")!

        let cache = SwisstopoVectorRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

        // load request to fill cache
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.startSynchronous()

        // immediately load request again, should be cached
        let dataTask2 = UBURLDataTask(url: url, session: session)
        dataTask2.addStateTransitionObserver { _, to, _ in
            XCTAssert(to != .fetching) // never make the request
        }
        let (_, _, info, _ ) = dataTask2.startSynchronous()
        XCTAssert(info != nil)
        XCTAssert(info!.cacheHit) // in cache

        // Cache should only be valid for 60 seconds
        sleep(70)

        // load request again, now request should return 302
        let dataTask3 = UBURLDataTask(url: url, session: session)
        var seenFetching = false
        dataTask3.addStateTransitionObserver { _, to, _ in
            if to == .fetching {
                seenFetching = true
            }
        }
        let (_, _, info3, _ ) = dataTask3.startSynchronous()

        XCTAssert(info3 != nil)
        XCTAssert(info3!.cacheHit)
        XCTAssert(seenFetching) // in cache, but request for 302

        // load request again, should be cached again
        let dataTask4 = UBURLDataTask(url: url, session: session)
        let (_, _, info4, _ ) = dataTask4.startSynchronous()
        XCTAssert(info4 != nil)
        XCTAssert(info4!.cacheHit) // in cache again

    }

    func testEmptyCache() {
        // Ensure that request with empty body is cached too

        let url = URL(string: "https://dev-static.swisstopo-app.ch/v10/stations/22/417/158.pbf")!

        let cache = SwisstopoVectorRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)

        // load request to fill cache

        let dataTask = UBURLDataTask(url: url, session: session)

        dataTask.startSynchronous()

        // load request again

        let dataTask2 = UBURLDataTask(url: url, session: session)
        dataTask2.addStateTransitionObserver { _, to, _ in
            XCTAssert(to != .fetching) // never make the request
        }
        let (_, _, info, _ ) = dataTask2.startSynchronous()

        XCTAssert(info != nil)
        XCTAssert(info!.cacheHit)

    }
}

class MeteoAutoRefreshCacheLogic: UBAutoRefreshCacheLogic {
    override var nextRefreshHeaderFieldName: String {
        return "x-amz-meta-next-refresh"
    }

    override var backoffIntervalHeaderFieldName: String {
        return "x-amz-meta-backoff"
    }

    override var expiresHeaderFieldName: String {
        return "x-amz-meta-best-before"
    }

    override var cacheControlHeaderFieldName: String {
        return "x-amz-meta-cache"
    }

    override var eTagHeaderFieldName: String {
        return "Etag"
    }

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
    override var nextRefreshHeaderFieldName: String {
        return "x-ms-meta-nextrefresh"
    }

    override var backoffIntervalHeaderFieldName: String {
        return "x-ms-meta-backoff"
    }

    override var expiresHeaderFieldName: String {
        return "x-ms-meta-bestbefore"
    }

    override var cacheControlHeaderFieldName: String {
        return "Cache-Control"
    }

    override var eTagHeaderFieldName: String {
        return "Etag"
    }

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
    override var nextRefreshHeaderFieldName: String {
        return "x-ms-meta-nextrefresh"
    }

    override var backoffIntervalHeaderFieldName: String {
        return "x-ms-meta-backoff"
    }

    override var expiresHeaderFieldName: String {
        return "x-ms-meta-bestbefore"
    }

    override var cacheControlHeaderFieldName: String {
        return "Cache-Control"
    }

    override var eTagHeaderFieldName: String {
        return "Etag"
    }

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
        return true
    }

    override func modifyCacheResult(proposed _: UBCacheResult, possible: UBCacheResult, reason _: UBBaseCachingLogic.CacheDecisionReason) -> UBCacheResult {
        return possible
    }
}