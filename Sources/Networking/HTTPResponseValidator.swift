//
//  HTTPResponseValidator.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// An object capable of validating an HTTP response
public protocol HTTPResponseValidator {
    /// Validates a HTTP response
    ///
    /// - Parameter response: The response to validate
    /// - Throws: In case the response is not valid
    func validateHTTPResponse(_ response: HTTPURLResponse, data: Data?) throws
}

/// A response validator block
public struct HTTPResponseValidatorBlock: HTTPResponseValidator {
    /// Validation Block
    public typealias ValidationBlock = (HTTPURLResponse, Data?) throws -> Void

    /// :nodoc:
    private let block: ValidationBlock

    /// Initializes the validator
    ///
    /// - Parameter validationBlock: The validation block to execute
    public init(_ validationBlock: @escaping ValidationBlock) {
        block = validationBlock
    }

    /// :nodoc:
    public func validateHTTPResponse(_ response: HTTPURLResponse, data: Data?) throws {
        try block(response, data)
    }
}

/// Validates the response body is not empty or null
public struct HTTPResponseBodyNotEmptyValidator: HTTPResponseValidator {
    /// Initalizes the validator
    public init() {}

    /// :nodoc:
    public func validateHTTPResponse(_: HTTPURLResponse, data: Data?) throws {
        guard let data = data, data.isEmpty == false else {
            throw NetworkingError.responseBodyIsEmpty
        }
    }
}

/// Validates the content type of the response
public struct HTTPResponseContentTypeValidator: HTTPResponseValidator {
    /// The expected MIME Type
    let expectedMIMEType: MIMEType

    /// Initalizes the validator
    ///
    /// - Parameter mimeType: The expected MIME Type
    public init(expectedMIMEType mimeType: MIMEType) {
        expectedMIMEType = mimeType
    }

    /// :nodoc:
    public func validateHTTPResponse(_ response: HTTPURLResponse, data _: Data?) throws {
        guard let value = response.getHeaderField(key: .contentType), let receivedMIME = MIMEType(string: value), expectedMIMEType.isEqual(receivedMIME, ignoreParameter: true) else {
            throw NetworkingError.responseMIMETypeValidationFailed
        }
    }
}

/// Validates the Status code of a response
public struct HTTPResponseStatusValidator: HTTPResponseValidator {
    /// A validation type
    private enum ValidationType {
        /// Validate a range of status codes
        case category(HTTPCodeCategory)
        /// Validates multiple status codes
        case multipleStatusCode([Int])
    }

    /// The type of validation
    private let type: ValidationType

    public init(_ category: HTTPCodeCategory) {
        type = .category(category)
    }

    public init(_ statusCode: StandardHTTPCode) {
        self.init(statusCode.rawValue)
    }

    public init(_ statusCode: Int) {
        self.init([statusCode])
    }

    public init(_ statusCodes: [StandardHTTPCode]) {
        self.init(statusCodes.map({ $0.rawValue }))
    }

    public init(_ statusCodes: [Int]) {
        type = .multipleStatusCode(statusCodes)
    }

    /// :nodoc:
    public func validateHTTPResponse(_ response: HTTPURLResponse, data _: Data?) throws {
        switch type {
        case let .category(category):
            guard category == response.statusCode.httpCodeCategory else {
                throw NetworkingError.responseStatusValidationFailed(status: response.statusCode)
            }
        case let .multipleStatusCode(statuses):
            guard statuses.contains(response.statusCode) else {
                throw NetworkingError.responseStatusValidationFailed(status: response.statusCode)
            }
        }
    }
}
