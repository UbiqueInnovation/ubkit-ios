//
//  UBURLSession+Configuration.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 03.04.19.
//

import Foundation

/// A configuration object that defines behavior and policies for a URL session.
public class UBURLSessionConfiguration {
    /// A copy of the configuration object for this session.
    public let sessionConfiguration: URLSessionConfiguration
    /// The evaluator per hosts
    public let hostsServerTrusts: [String: UBServerTrustEvaluator]
    /// The default evaluator to use
    public let defaultServerTrust: UBServerTrustEvaluator?
    /// If requests are allowed to redirect
    public let allowRedirections: Bool
    /// If requests have the correct headers, then the session will schedule a call in the future for refreshing the data.
    public let cachingLogic: UBCachingLogic?
    /// The proxy setting for the URLSessionConfiguration,
    public let proxy: UBURLSessionConfigurationProxy?

    /// Initializes a configuration object
    ///
    /// The configuration will include the "App-Version", "OS-Version" and Proxy-Authorization" headers in addition to all the headers you pass in the sessionConfiguration object. If a conflict occures then the header in the session configuration is preferred.
    ///
    /// - Parameters:
    ///   - sessionConfiguration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, credential storage, and so on.
    ///   - hostsServerTrusts: A dictionary of Hosts (keys) and their corresponding evaluator. It is highly recommended that you configure for each possible host an evaluator then MITM attacks will be nearly impossible.
    ///   - defaultServerTrust: A evaluator to use in case no matche is found in the list of hosts. If no default is set and the host is not found then the default OS behaviour is executed.
    ///   - allowRedirections: Set this flag to `false` if you do not want any redirection. If response wants to redirect, and the flag is set to false, the redirection will not happpen and the data task will be called with the response that caused the redirection.
    ///   - cachingLogic: If set the caching will use the passed object. If not then the caching will be the default by the URLSession.
    public init(
        sessionConfiguration: URLSessionConfiguration = .default, hostsServerTrusts: [String: UBServerTrustEvaluator] = [:],
        defaultServerTrust: UBServerTrustEvaluator? = nil, allowRedirections: Bool = true, cachingLogic: UBCachingLogic? = nil,
        proxy: UBURLSessionConfigurationProxy? = nil
    ) {
        let sessionConfiguration = sessionConfiguration.copy() as! URLSessionConfiguration
        if let proxy {
            var proxyDict = [AnyHashable: Any]()
            proxyDict["HTTPSEnable"] = 1
            proxyDict["HTTPSProxy"] = proxy.host
            proxyDict["HTTPSPort"] = proxy.port
            sessionConfiguration.connectionProxyDictionary = proxyDict
        }
        self.sessionConfiguration = sessionConfiguration
        self.hostsServerTrusts = hostsServerTrusts
        self.defaultServerTrust = defaultServerTrust
        self.allowRedirections = allowRedirections
        self.cachingLogic = cachingLogic ?? UBAutoRefreshCacheLogic(qos: sessionConfiguration.networkServiceType.equivalentDispatchQOS)
        self.proxy = proxy

        applyDefaultHeaders(configuration: sessionConfiguration, proxy: proxy)
    }

    private func applyDefaultHeaders(configuration: URLSessionConfiguration, proxy: UBURLSessionConfigurationProxy?) {
        var headers: [AnyHashable: Any] = [:]

        // Add encoding
        headers[UBHTTPHeaderField.StandardKeys.acceptEncoding.rawValue] = "gzip"

        // Add app information
        if let info = Bundle.main.infoDictionary,
            let appName = info[kCFBundleNameKey as String] as? String
        {
            let shortVersionNumber = info["CFBundleShortVersionString"] as? String
            let buildNumber = info[kCFBundleVersionKey as String] as? String
            headers["App-Version"] = "\(appName) v\(shortVersionNumber ?? "unknown") (\(buildNumber ?? "unknown"))"
        }

        // Add OS information
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        #if os(iOS)
            headers["OS-Version"] = "iOS \(osVersionString)"
        #elseif os(watchOS)
            headers["OS-Version"] = "watchOS \(osVersionString)"
        #elseif os(tvOS)
            headers["OS-Version"] = "tvOS \(osVersionString)"
        #elseif os(macOS)
            headers["OS-Version"] = "macOS \(osVersionString)"
        #elseif os(visionOS)
            headers["OS-Version"] = "visionOS \(osVersionString)"
        #endif

        if let proxy, let username = proxy.username, let password = proxy.password,
            let data = "\(username):\(password)".data(using: .utf8)
        {
            headers[UBHTTPHeaderField.StandardKeys.proxyAuthorization.rawValue] = "Basic " + data.base64EncodedString()
        }

        if let configHeaders = configuration.httpAdditionalHeaders {
            for header in configHeaders {
                headers[header.key] = header.value
            }
        }

        configuration.httpAdditionalHeaders = headers
    }
}

extension URLRequest.NetworkServiceType {
    /// Returns the equivalent dispatch queue qos from a network service type
    var equivalentDispatchQOS: DispatchQoS {
        let qos: DispatchQoS
        switch self {
            case .background:
                qos = .background
            case .responsiveData:
                qos = .userInitiated
            case .video, .voip, .voice, .callSignaling, .avStreaming, .responsiveAV:
                qos = .userInteractive
            case .default:
                qos = .default
            @unknown default:
                fatalError()
        }
        return qos
    }
}
