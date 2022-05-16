//
//  File.swift
//
//
//  Created by Nicolas Märki on 16.05.22.
//

import UBFoundation
import XCTest

@available(iOS 13.0.0, *)
class ConcurrentNetworkTests: XCTestCase {
    func testBasicRequest() async throws {
        let _ = try await UBURLDataTask.loadOnce(request: sampleRequest)
    }

    func testRequestError() async throws {
        do {
            let _ = try await UBURLDataTask.loadOnce(request: brokenSampleRequest)
            XCTAssert(false)
        } catch {
            // error is good
        }
    }

    func testCronStream() async throws {
        let stream = UBURLDataTask.startCronStream(request: sampleRequest, session: fastCronSession)
        var count = 0
        for try await _ in stream {
            count += 1
            if count >= 3 {
                return
            }
        }
    }

    private var sampleRequest: UBURLRequest {
        let url = URL(string: "https://s3-eu-central-1.amazonaws.com/app-test-static-fra.meteoswiss-app.ch/v1/warnings_with_outlook_with_naturalhazards_de.json")!
        let request = UBURLRequest(url: url)
        return request
    }

    private var brokenSampleRequest: UBURLRequest {
        let url = URL(string: "https://s3-eu-central-1.amazonaws.com/DOES_NOT_EXIST.json")!
        let request = UBURLRequest(url: url)
        return request
    }

    private var fastCronSession: UBDataTaskURLSession {
        let cache = MeteoAutoRefreshCacheLogic()
        let conf = UBURLSessionConfiguration(cachingLogic: cache)
        let c = URLCache(memoryCapacity: 1024 * 1024 * 4, diskCapacity: 1024 * 1024 * 10, diskPath: "meteo")
        c.removeAllCachedResponses()
        conf.sessionConfiguration.urlCache = c
        let session = UBURLSession(configuration: conf)
        return session
    }
}

private class MeteoAutoRefreshCacheLogic: UBAutoRefreshCacheLogic {
    override var nextRefreshHeaderFieldName: String {
        "x-amz-meta-next-refresh"
    }

    override var backoffIntervalHeaderFieldName: String {
        "x-amz-meta-backoff"
    }

    override var expiresHeaderFieldName: String {
        "x-amz-meta-best-before"
    }

    override var cacheControlHeaderFieldName: String {
        "x-amz-meta-cache"
    }

    override var eTagHeaderFieldName: String {
        "Etag"
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
