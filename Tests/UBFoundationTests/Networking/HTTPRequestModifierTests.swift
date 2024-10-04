//
//  HTTPRequestModifierTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 01.04.19.
//

import UBFoundation
import XCTest

class HTTPRequestModifierTests: XCTestCase {
    let request = UBURLRequest(url: URL(string: "http://ubique.ch")!)

    func testGroupModifiers() {
        let ex = expectation(description: "Request Modification")
        let ba1 = UBURLRequestBasicAuthorization(login: "login1", password: "password")
        let ba2 = UBURLRequestBasicAuthorization(login: "login", password: "password")
        let group = UBURLRequestModifierGroup(modifiers: [ba1, ba2])
        group.modifyRequest(request) { result in
            switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(newRequest):
                    let value = newRequest.value(forHTTPHeaderField: "Authorization")
                    let expectedValue = "Basic bG9naW46cGFzc3dvcmQ="
                    XCTAssertEqual(value, expectedValue)
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 30)
    }

    func testGroupModifiersEmpty() {
        let ex = expectation(description: "Request Modification")
        let group = UBURLRequestModifierGroup()
        group.modifyRequest(request) { result in
            switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .success:
                    break
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 30)
    }

    func testGroupModifiersFailure() {
        let ex = expectation(description: "Request Modification")
        let m1 = UBURLRequestBasicAuthorization(login: "login1", password: "password")
        let group = UBURLRequestModifierGroup(modifiers: [m1])
        let m2 = FailureModifier()
        group.append(m2)
        group.modifyRequest(request) { result in
            switch result {
                case let .failure(error):
                    XCTAssertEqual(error as? Err, .x)
                case .success:
                    XCTFail()
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 30)
    }

    func testGroupModifiersCancel() {
        let ex = expectation(description: "Request Modification")
        let m1 = SleeperModifier(duration: 0.3)
        let m2 = UBURLRequestBasicAuthorization(login: "login", password: "password")
        let group = UBURLRequestModifierGroup(modifiers: [m1, m2])
        group.modifyRequest(request) { _ in
            XCTFail()
        }
        group.cancelCurrentModification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ex.fulfill()
        }
        wait(for: [ex], timeout: 30)
    }

    func testBasicAuthorization() {
        let ex = expectation(description: "Request Modification")
        let ba = UBURLRequestBasicAuthorization(login: "login", password: "password")
        ba.modifyRequest(request) { result in
            switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(newRequest):
                    let value = newRequest.value(forHTTPHeaderField: "Authorization")
                    let expectedValue = "Basic bG9naW46cGFzc3dvcmQ="
                    XCTAssertEqual(value, expectedValue)
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 30)
    }

    func testTokenAuthorization() {
        let ex = expectation(description: "Request Modification")
        let ba = MockTokenAuthorization()
        ba.modifyRequest(request) { result in
            switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(newRequest):
                    let value = newRequest.value(forHTTPHeaderField: "Authorization")
                    let expectedValue = "Bearer AbCdEf123456"
                    XCTAssertEqual(value, expectedValue)
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 30)
    }

    func testTokenFailure() {
        let ex = expectation(description: "Request Modification")
        let ba = MockTokenAuthorization(error: Err.x)
        ba.modifyRequest(request) { result in
            switch result {
                case let .failure(error):
                    XCTAssertEqual(error as? Err, .x)
                case .success:
                    XCTFail()
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 30)
    }

    func testAcceptedLanguage() {
        let ex = expectation(description: "Request Modification")

        guard let testBundlePath = Bundle.module.path(forResource: "TestResources/LocalizationTestBundle", ofType: nil),
              let testBundle = Bundle(path: testBundlePath) else {
            fatalError("No test bundle found")
        }
        let frenchCHLocalization = UBLocalization(locale: Locale(identifier: "fr_CH"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        let ba = UBURLRequestAcceptedLanguageModifier(includeRegion: false, localization: frenchCHLocalization)
        ba.modifyRequest(request) { result in
            switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(newRequest):
                    let value = newRequest.value(forHTTPHeaderField: "Accept-Language")
                    let expectedValue = "fr;q=1.0,en;q=0.9"
                    XCTAssertEqual(value, expectedValue)
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 30)
    }
}

private enum Err: Error {
    case x
}

private struct SleeperModifier: UBURLRequestModifier {
    let duration: TimeInterval
    func modifyRequest(_ request: UBURLRequest, completion: @escaping @Sendable (Result<UBURLRequest, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion(.success(request))
        }
    }
}

private struct FailureModifier: UBURLRequestModifier {
    func modifyRequest(_: UBURLRequest, completion: @escaping (Result<UBURLRequest, Error>) -> Void) {
        completion(.failure(Err.x))
    }
}

private final class MockTokenAuthorization: UBURLRequestTokenAuthorization {
    let token: String = "AbCdEf123456"
    let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func getToken(completion: (Result<String, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(token))
        }
    }
}
