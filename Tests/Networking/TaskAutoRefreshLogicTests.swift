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
        dataTask.addCompletionHandler { result, _, _, _ in

			ex.fulfill()
        }
        dataTask.start()
		self.wait(for: [ex], timeout: 10000)

		// load request again

		let dataTask2 = UBURLDataTask(url: url, session: session)

		let ex2 = self.expectation(description: "s2")
		dataTask2.addCompletionHandler { result, _, info, _ in

			XCTAssertNotNil(info)
			XCTAssert(info!.cacheHit)
			XCTAssertNotNil(info!.metrics)

			ex2.fulfill()
		}
		dataTask2.start()
		self.wait(for: [ex2], timeout: 10000)

    }

	func testNoCacheHeaders() {

		// Load Request with default headers and no cache

		let url = URL(string: "https://s3-eu-central-1.amazonaws.com/app-test-static-fra.meteoswiss-app.ch/v1/warnings_with_outlook_with_naturalhazards_de.json")!

		// load request to (not) fill cache

		let dataTask = UBURLDataTask(url: url)

		let ex = expectation(description: "s")
		dataTask.addCompletionHandler { result, _, _, _ in

			ex.fulfill()
		}
		dataTask.start()
		self.wait(for: [ex], timeout: 10000)

		// load request again

		let dataTask2 = UBURLDataTask(url: url)

		let ex2 = self.expectation(description: "s2")
		dataTask2.addCompletionHandler { result, _, info, _ in

			XCTAssertNotNil(info)
			XCTAssertFalse(info!.cacheHit)
			XCTAssertNotNil(info!.metrics)

			ex2.fulfill()
		}
		dataTask2.start()
		self.wait(for: [ex2], timeout: 10000)

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
}
