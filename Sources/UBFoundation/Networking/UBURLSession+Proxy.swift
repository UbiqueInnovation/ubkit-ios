//
//  UBURLSessionConfigurationProxy.swift
//  
//
//  Created by Sandro Kolly on 07.05.2024.
//

import Foundation

/// A protocol to set a proxy on the UBURLSessionConfiguration
///
/// Currently only basic auth is supported for proxy. The auth header is set in the configuration httpAdditionalHeaders.
/// If the proxy needs a different auth, this can be overwritten in the session, which takes priority over the httpAdditionalHeaders.
public protocol UBURLSessionConfigurationProxy {
    var host: String { get }
    var port: Int { get }
    var username: String? { get }
    var password: String? { get }
}
