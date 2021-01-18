//
//  HTTPURLResponse+Validator.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// An object capable of validating an HTTP response
public protocol UBHTTPURLResponseValidator {
    /// Validates a HTTP response
    ///
    /// - Parameter response: The response to validate
    /// - Throws: In case the response is not valid
    func validateHTTPResponse(_ response: HTTPURLResponse) throws
}

/// A response validator block
public struct UBHTTPResponseValidatorBlock: UBHTTPURLResponseValidator {
    /// Validation Block
    public typealias ValidationBlock = (HTTPURLResponse) throws -> Void

    /// :nodoc:
    private let block: ValidationBlock

    /// Initializes the validator
    ///
    /// - Parameter validationBlock: The validation block to execute
    public init(_ validationBlock: @escaping ValidationBlock) {
        block = validationBlock
    }

    /// :nodoc:
    public func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        try block(response)
    }
}

/// Validates the content type of the response
public struct UBHTTPResponseContentTypeValidator: UBHTTPURLResponseValidator {
    /// The expected MIME Type
    let expectedMIMEType: UBMIMEType

    /// Initalizes the validator
    ///
    /// - Parameter mimeType: The expected MIME Type
    public init(expectedMIMEType mimeType: UBMIMEType) {
        expectedMIMEType = mimeType
    }

    /// :nodoc:
    public func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        guard let value = response.ub_getHeaderField(key: .contentType), let receivedMIME = UBMIMEType(string: value), expectedMIMEType.isEqual(receivedMIME, ignoreParameter: true) else {
            throw UBInternalNetworkingError.responseMIMETypeValidationFailed
        }
    }
}

/// Validates the Status code of a response
public struct UBHTTPResponseStatusValidator: UBHTTPURLResponseValidator {
    /// A validation type
    private enum ValidationType {
        /// Validate a range of status codes
        case category(UBHTTPCodeCategory)
        /// Validates multiple status codes
        case multipleStatusCode([Int])
    }

    /// The type of validation
    private let type: ValidationType

    /// Initializes the validator
    ///
    /// - Parameter category: A category of status codes
    public init(_ category: UBHTTPCodeCategory) {
        type = .category(category)
    }

    /// Initializes the validator
    ///
    /// - Parameter statusCode: A standard status code
    public init(_ statusCode: UBStandardHTTPCode) {
        self.init(statusCode.rawValue)
    }

    /// Initializes the validator
    ///
    /// - Parameter statusCode: A status codes
    public init(_ statusCode: Int) {
        self.init([statusCode])
    }

    /// Initializes the validator
    ///
    /// - Parameter statusCodes: An array of status codes
    public init(_ statusCodes: [UBStandardHTTPCode]) {
        self.init(statusCodes.map { $0.rawValue })
    }

    /// Initializes the validator
    ///
    /// - Parameter statusCodes: An array of status codes
    public init(_ statusCodes: [Int]) {
        type = .multipleStatusCode(statusCodes)
    }

    /// :nodoc:
    public func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        switch type {
        case let .category(category):
            guard category == response.statusCode.ub_httpCodeCategory else {
                throw UBInternalNetworkingError.responseStatusValidationFailed(status: response.statusCode)
            }
        case let .multipleStatusCode(statuses):
            guard statuses.contains(response.statusCode) else {
                throw UBInternalNetworkingError.responseStatusValidationFailed(status: response.statusCode)
            }
        }
    }
}
