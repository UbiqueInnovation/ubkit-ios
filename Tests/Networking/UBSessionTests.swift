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
//        let url = URL(string: "https://google.com")!
//
//        enum Err: Error {
//            case x
//        }
//        struct F: ServerTrustEvaluator {
//            func evaluate(_: SecTrust, forHost _: String) throws {
//                throw Err.x
//            }
//        }
//
//        let evaluator = PinnedCertificatesTrustEvaluator(certificates: Bundle(for: UBSessionTests.self).certificates, acceptSelfSignedCertificates: false, performDefaultValidation: true, validateHost: true)
//        let configuration = UBURLSessionConfiguration(defaultServerTrust: evaluator)
//        let session = UBURLSession(configuration: configuration)
        let session = UBURLSession()
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, response, _, _ in
            print(result)
            print(response)
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
        session.invalidateAndCancel()
    }
}
