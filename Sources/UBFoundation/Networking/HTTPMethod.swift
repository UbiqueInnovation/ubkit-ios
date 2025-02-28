//
//  HTTPMethod.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

/// HTTP defines a set of request methods to indicate the desired action to be performed for a given resource.
public enum UBHTTPMethod: String, Sendable {
    /// The GET method requests a representation of the specified resource. Requests using GET should only retrieve data.
    case get = "GET"
    /// The HEAD method asks for a response identical to that of a GET request, but without the response body.
    case head = "HEAD"
    /// The POST method is used to submit an entity to the specified resource, often causing a change in state or side effects on
    case post = "POST"
    /// The PUT method replaces all current representations of the target resource with the request payload.
    case put = "PUT"
    /// The DELETE method deletes the specified resource.
    case delete = "DELETE"
    /// The TRACE method performs a message loop-back test along the path to the target resource.
    case trace = "TRACE"
    /// The PATCH method is used to apply partial modifications to a resource.
    case patch = "PATCH"
}
