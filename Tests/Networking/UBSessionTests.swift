//
//  UBSessionTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import UBFoundation
import XCTest

class UBSessionTests: XCTestCase {
    func testX() {
        let ex = expectation(description: "s")
        let url = URL(string: "http://ubique.ch")!
        let session = UBURLSession(configuration: .default, delegateQueue: OperationQueue())
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, response, _ in
            print(result)
            print(response)
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
        session.invalidateAndCancel()
    }

    func testC() {
    }
}
