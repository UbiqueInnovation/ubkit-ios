//
//  HTTPCode+Category.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//

import Foundation

/// A cluster of HTTP code
public enum UBHTTPCodeCategory {
    /// Code is outside of the known ranges
    case uncategorized
    /// Informational status
    case informational
    /// Success status
    case success
    /// Redirection status
    case redirection
    /// Client Error Status
    case clientError
    /// Server Error Status
    case serverError

    /// Initializes an HTTP code category
    ///
    /// - Parameter code: The HTTP code
    public init(code: Int) {
        switch code {
        case 100 ..< 200:
            self = .informational
        case 200 ..< 300:
            self = .success
        case 300 ..< 400:
            self = .redirection
        case 400 ..< 500:
            self = .clientError
        case 500 ..< 600:
            self = .serverError
        default:
            self = .uncategorized
        }
    }

    /// :nodoc:
    public static func == (left: UBHTTPCodeCategory, right: Int) -> Bool {
        left == UBHTTPCodeCategory(code: right)
    }

    /// :nodoc:
    public static func == (left: Int, right: UBHTTPCodeCategory) -> Bool {
        right == left
    }

    /// :nodoc:
    public static func == (left: HTTPURLResponse, right: UBHTTPCodeCategory) -> Bool {
        left.statusCode == right
    }

    /// :nodoc:
    public static func == (left: UBHTTPCodeCategory, right: HTTPURLResponse) -> Bool {
        right == left
    }

    /// :nodoc:
    public static func != (left: UBHTTPCodeCategory, right: Int) -> Bool {
        left != UBHTTPCodeCategory(code: right)
    }

    /// :nodoc:
    public static func != (left: Int, right: UBHTTPCodeCategory) -> Bool {
        right != left
    }

    /// :nodoc:
    public static func != (left: HTTPURLResponse, right: UBHTTPCodeCategory) -> Bool {
        left.statusCode != right
    }

    /// :nodoc:
    public static func != (left: UBHTTPCodeCategory, right: HTTPURLResponse) -> Bool {
        right != left
    }
}
