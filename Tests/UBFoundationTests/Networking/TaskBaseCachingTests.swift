//
//  BaseCachingTests.swift
//  
//
//  Created by Zeno Koller on 27.05.22.
//

import UBFoundation
import XCTest

class BaseCachingTests: XCTestCase {

    func testMethodChange() {
        // Ensure that requests with different HTTP methods are not cached

        let url = URL(string: "https://dev-static.swisstopo-app.ch/v10/stations/22/417/158.pbf")!

        let configuration = UBURLSessionConfiguration()
        configuration.sessionConfiguration.networkServiceType = .responsiveData
        let session = UBURLSession(configuration: configuration)

        let res = expectation(description: "res")
        session.reset {
            res.fulfill()
        }
        wait(for: [res], timeout: 10000)

        // load request to fill cache
        var request = UBURLRequest(url: url)
        request.httpMethod = .head
        let dataTask = UBURLDataTask(request: request)
        dataTask.startSynchronous()

        // load request again with different method
        request.httpMethod = .get
        let dataTask2 = UBURLDataTask(request: request)
        let (_, _, info, _) = dataTask2.startSynchronous()

        XCTAssert(info != nil)
        XCTAssert(info!.cacheHit == false)
    }
}
