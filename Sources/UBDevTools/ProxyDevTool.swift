//
//  ProxyDevTools.swift
//
//
//  Created by Sandro Kolly on 10.05.2024.
//

import UBFoundation
import UIKit

class UBDevToolsProxyHelper {
    static let shared = UBDevToolsProxyHelper()

    fileprivate private(set) var proxy: Proxy? = nil

    func setProxy(host: String, port: Int, username: String?, password: String?, proxiedDomains: [String]?) {
        proxy = Proxy(host: host, port: port, username: username, password: password, proxiedDomains: proxiedDomains)
    }

    fileprivate struct Proxy: UBURLSessionConfigurationProxy {
        var host: String
        var port: Int
        var username: String?
        var password: String?
        var proxiedDomains: [String]?
    }
}

public class UBFriendlyEvaluator: UBServerTrustEvaluator {
    public func evaluate(_ trust: SecTrust, forHost host: String) throws {
        // on purpose not throwing, we allow it all
    }
}

@available(iOS 14.0, *)
public extension Networking {
    /// This is a copy of the sharedSession including the proxy and friendly trust settings
    static let friendlyDefaultSession: UBURLSession = {
        guard DevToolsView.enableNetworkingProxySettings,
              let proxy = UBDevToolsProxyHelper.shared.proxy
        else { return Networking.sharedSession }

        let queue = OperationQueue()
        queue.name = "Friendly UBURLSession Shared"
        queue.qualityOfService = .userInitiated

        let configuration: UBURLSessionConfiguration
        if let domains = proxy.proxiedDomains, domains.isEmpty == false {
            let trusts: [String: UBFriendlyEvaluator] = domains.reduce([:], { var dict = $0; dict[$1] = UBFriendlyEvaluator(); return dict })
            configuration = UBURLSessionConfiguration(hostsServerTrusts: trusts, proxy: UBDevToolsProxyHelper.shared.proxy)
        } else {
            configuration = UBURLSessionConfiguration(defaultServerTrust: UBFriendlyEvaluator(), proxy: UBDevToolsProxyHelper.shared.proxy)
        }

        configuration.sessionConfiguration.networkServiceType = .responsiveData
        return UBURLSession(configuration: configuration, delegateQueue: queue)
    }()
}
