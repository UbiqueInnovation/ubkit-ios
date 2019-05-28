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

//    func testNoCacheHeaders() {
//        let ex = expectation(description: "s")
//        let url = URL(string: "https://s3-eu-central-1.amazonaws.com/app-test-static-fra.meteoswiss-app.ch/v1/warnings_with_outlook_with_naturalhazards_de.json")!
//
//        let cache = MeteoAutoRefreshCacheLogic(autoRefreshExpiredCache: false)
//        let conf = UBURLSessionConfiguration(cachingLogic: cache)
//        conf.sessionConfiguration.urlCache = c
//        let session = UBURLSession(configuration: conf)
//        let dataTask = UBURLDataTask(url: url, session: session)
//        dataTask.addCompletionHandler { result, _, _, _ in
//            print(result)
//            ex.fulfill()
//        }
//        dataTask.start()
//        waitForExpectations(timeout: 10000, handler: nil)
//    }
}

class MeteoAutoRefreshCacheLogic: AutoRefreshCacheLogic {
    override var nextRefreshHeaderFieldName: String {
        return "x-amz-meta-next-refresh"
    }

    override var backoffHeaderFieldName: String {
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
}
