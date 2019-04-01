//
//  HTTPRequestBasicAuthorization.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 01.04.19.
//

import Foundation

/// A basic authorization of login and password
public class HTTPRequestBasicAuthorization: HTTPRequestModifier {
    /// :nodoc:
    private let serial = DispatchQueue(label: "Basic Authorization")

    /// :nodoc:
    private var _login: String
    /// The login details
    public var login: String {
        return serial.sync {
            _login
        }
    }

    /// :nodoc:
    private var _password: String
    /// The password
    public var password: String {
        return serial.sync {
            _password
        }
    }

    /// Initializes a basic authorisation request modifier
    ///
    /// - Parameters:
    ///   - login: The login
    ///   - password: The password
    public init(login: String, password: String) {
        _login = login
        _password = password
    }

    /// Set the login and password
    ///
    /// - Parameters:
    ///   - login: The new login
    ///   - password: The new password
    public func set(login: String, password: String) {
        serial.sync {
            _login = login
            _password = password
        }
    }

    /// :nodoc:
    public func modifyRequest(_ originalRequest: HTTPURLRequest, completion: @escaping (Result<HTTPURLRequest>) -> Void) {
        // https://tools.ietf.org/html/rfc7617
        var loginString: String = ""
        serial.sync {
            loginString = "\(_login):\(_password)"
        }
        let loginData = loginString.data(using: .utf8)! // Internally all strings are stored in utf8. This never fails
        let base64LoginString = loginData.base64EncodedString()
        var modifierRequest = originalRequest
        modifierRequest.setHTTPHeaderField(HTTPHeaderField(key: .authorization, value: "Basic \(base64LoginString)"))
        completion(.success(modifierRequest))
    }
}
