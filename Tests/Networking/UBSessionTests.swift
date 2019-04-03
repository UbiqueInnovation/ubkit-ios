//
//  UBSessionTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import UBFoundation
import XCTest

class UBSessionTests: XCTestCase {
    let testBundle: Bundle = {
        guard let testBundlePath = Bundle(for: LocalizationTests.self).path(forResource: "NetworkingTestBundle", ofType: nil),
            let testBundle = Bundle(path: testBundlePath) else {
            fatalError("No test bundle found")
        }
        return testBundle
    }()

    func testNoRedirection() {
        let ex = expectation(description: "s")
        let url = URL(string: "http://ubique.ch")!
        let configuration = UBURLSessionConfiguration(allowRedirections: false)
        let session = UBURLSession(configuration: configuration)
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, response, _, _ in
            switch result {
            case .success:
                break
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
            XCTAssertEqual(response?.statusCode.standardHTTPCode, StandardHTTPCode.found)
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testRedirection() {
        let ex = expectation(description: "s")
        let url = URL(string: "http://ubique.ch")!
        let dataTask = UBURLDataTask(url: url, session: UBURLSession.sharedBackground)
        dataTask.addCompletionHandler { result, response, _, _ in
            switch result {
            case .success:
                break
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
            XCTAssertEqual(response?.statusCode.standardHTTPCode, StandardHTTPCode.ok)
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testURLValidationFailed() {
        let ex = expectation(description: "s")
        let url = URL(string: "https://www.ubique.ch")!
        let dataTask = UBURLDataTask(url: url)
        enum Err: Error { case x }
        dataTask.addResponseValidator { _ in
            throw Err.x
        }
        dataTask.addCompletionHandler { result, _, _, _ in
            switch result {
            case .success:
                XCTFail()
            case let .failure(error):
                XCTAssertEqual(error as? Err, Err.x)
            }
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testValidCertificatePinning() {
        let ex = expectation(description: "s")
        let url = URL(string: "https://www.ubique.ch")!
        let evaluator = PinnedCertificatesTrustEvaluator(certificates: testBundle.certificates)
        let configuration = UBURLSessionConfiguration(hostsServerTrusts: ["www.ubique.ch": evaluator])
        let session = UBURLSession(configuration: configuration)
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, response, _, _ in
            switch result {
            case .success:
                break
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
            XCTAssertEqual(response?.statusCode.standardHTTPCode, StandardHTTPCode.ok)
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testInvalidCertificatePinning() {
        let ex = expectation(description: "s")
        let url = URL(string: "https://www.google.com")!
        let evaluator = PinnedCertificatesTrustEvaluator(certificates: testBundle.certificates)
        let configuration = UBURLSessionConfiguration(defaultServerTrust: evaluator)
        let session = UBURLSession(configuration: configuration)
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, _, _, _ in
            switch result {
            case .success:
                XCTFail("Certificate Pinning should have failed")
            case let .failure(error):
                XCTAssertEqual(error as? NetworkingError, NetworkingError.certificateValidationFailed)
            }
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testExpiredCertificate() {
        let ex = expectation(description: "s")
        let url = URL(string: "https://expired.badssl.com/")!
        let evaluator = DefaultTrustEvaluator()
        let configuration = UBURLSessionConfiguration(defaultServerTrust: evaluator)
        let session = UBURLSession(configuration: configuration)
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, _, _, _ in
            switch result {
            case .success:
                XCTFail("Certificate Pinning should have failed")
            case let .failure(error):
                XCTAssertEqual(error as? NetworkingError, NetworkingError.certificateValidationFailed)
            }
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testWrongHostCertificate() {
        let ex = expectation(description: "s")
        let url = URL(string: "https://wrong.host.badssl.com/")!
        let evaluator = DefaultTrustEvaluator()
        let configuration = UBURLSessionConfiguration(defaultServerTrust: evaluator)
        let session = UBURLSession(configuration: configuration)
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, _, _, _ in
            switch result {
            case .success:
                XCTFail("Certificate Pinning should have failed")
            case let .failure(error):
                XCTAssertEqual(error as? NetworkingError, NetworkingError.certificateValidationFailed)
            }
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSelfSignedCertificate() {
        let ex = expectation(description: "s")
        let url = URL(string: "https://self-signed.badssl.com/")!
        let evaluator = DefaultTrustEvaluator()
        let configuration = UBURLSessionConfiguration(defaultServerTrust: evaluator)
        let session = UBURLSession(configuration: configuration)
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, _, _, _ in
            switch result {
            case .success:
                XCTFail("Certificate Pinning should have failed")
            case let .failure(error):
                XCTAssertEqual(error as? NetworkingError, NetworkingError.certificateValidationFailed)
            }
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSelfSignedCertificatePass() {
        let ex = expectation(description: "s")
        let url = URL(string: "https://self-signed.badssl.com/")!
        let evaluator = PinnedCertificatesTrustEvaluator(certificates: testBundle.certificates, acceptSelfSignedCertificates: true, performDefaultValidation: false, validateHost: false)
        let configuration = UBURLSessionConfiguration(defaultServerTrust: evaluator)
        let session = UBURLSession(configuration: configuration)
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, _, _, _ in
            switch result {
            case .success:
                break
            case let .failure(error):
                XCTFail("Self signed certificate should have worked \(error)")
            }
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDisableEvaluation() {
        let ex = expectation(description: "s")
        let url = URL(string: "https://self-signed.badssl.com/")!
        let evaluator = DisabledEvaluator()
        let configuration = UBURLSessionConfiguration(defaultServerTrust: evaluator)
        let session = UBURLSession(configuration: configuration)
        let dataTask = UBURLDataTask(url: url, session: session)
        dataTask.addCompletionHandler { result, _, _, _ in
            switch result {
            case .success:
                break
            case let .failure(error):
                XCTFail("Self signed certificate should have worked \(error)")
            }
            ex.fulfill()
        }
        dataTask.start()
        waitForExpectations(timeout: 10, handler: nil)
    }
}
