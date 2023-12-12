//
//  PostCompletionTest.swift
//
//
//  Created by Nicolas Märki on 12.12.2023.
//

import UBFoundation
import XCTest

class PostCompletionTest: XCTestCase {
    func testPostCompletionSuccess() {
        let url = URL(string: "https://github.com/UbiqueInnovation/ubkit-ios")!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = UBURLDataTask(request: request)

        let exp = expectation(description: "post")
        exp.expectedFulfillmentCount = 2
        task.postCompletionHandler = { result in
            switch result {
                case .success:
                    exp.fulfill()
                default: break
            }
        }

        struct Body: Decodable {
            let title: String
        }

        let exp2 = expectation(description: "json")
        task.addCompletionHandler(decoder: .json(Body.self)) { result, _, _, _ in
            exp2.fulfill()
        }

        let exp3 = expectation(description: "string")
        task.addCompletionHandler(decoder: .string) { result, _, _, _ in
            exp3.fulfill()
        }

        task.start()

        wait(for: [exp, exp2, exp3])
    }

    func testPostCompletionError() {
        let url = URL(string: "https://github.com/UbiqueInnovation/ubkit-ios-not-existing")!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = UBURLDataTask(request: request)

        let exp = expectation(description: "post")
        exp.expectedFulfillmentCount = 2
        task.postCompletionHandler = { result in
            switch result {
                case .failure(.internal(.requestFailed(httpStatusCode: 404))):
                    exp.fulfill()
                default: break
            }
        }

        struct Body: Decodable {
            let title: String
        }

        let exp2 = expectation(description: "json")
        task.addCompletionHandler(decoder: .json(Body.self)) { result, _, _, _ in
            exp2.fulfill()
        }

        let exp3 = expectation(description: "string")
        task.addCompletionHandler(decoder: .string) { result, _, _, _ in
            exp3.fulfill()
        }

        task.start()

        wait(for: [exp, exp2, exp3])
    }
}
