//
//  ProxyDevTool.swift
//
//
//  Created by Sandro Kolly on 10.05.2024.
//

import UBFoundation
import UIKit

@MainActor
class UBDevToolsProxyHelper {
    static let shared = UBDevToolsProxyHelper()

    fileprivate private(set) var proxy: Proxy?

    func setProxy(host: String, port: Int, username: String?, password: String?) {
        proxy = Proxy(host: host, port: port, username: username, password: password)
    }

    fileprivate struct Proxy: UBURLSessionConfigurationProxy {
        var host: String
        var port: Int
        var username: String?
        var password: String?
    }
}

public final class UBFriendlyEvaluator: UBServerTrustEvaluator {
    public func evaluate(_ trust: SecTrust, forHost host: String) throws {
        // on purpose not throwing, we allow it all
    }
}

public extension UBURLSession {
    /// This is a copy of the sharedSession including the proxy and friendly trust settings
    @MainActor
    static let friendlySharedSession: UBURLSession = {
        guard DevToolsView.enableNetworkingProxySettings else { return UBURLSession.sharedSession }

        let queue = OperationQueue()
        queue.name = "Friendly UBURLSession Shared"
        queue.qualityOfService = .userInitiated

        let proxy: UBDevToolsProxyHelper.Proxy? =
            if let host = DevToolsView.proxySettingsHost, host.isEmpty == false,
                let port = DevToolsView.proxySettingsPort
            {
                UBDevToolsProxyHelper.Proxy(host: host, port: port)
            } else if let devProy = UBDevToolsProxyHelper.shared.proxy {
                devProy
            } else {
                nil
            }

        let configuration = UBURLSessionConfiguration(defaultServerTrust: UBFriendlyEvaluator(), proxy: proxy)
        configuration.sessionConfiguration.networkServiceType = .responsiveData
        return UBURLSession(configuration: configuration, delegateQueue: queue)
    }()
}
