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
    public let hostsServerTrusts: [String: ServerTrustEvaluator]
    /// The default evaluator to use
    public let defaultServerTrust: ServerTrustEvaluator?
    /// If requests are allowed to redirect
    public let allowRedirections: Bool
    /// If requests have the correct headers, then the session will schedule a call in the future for refreshing the data.
    public let allowAutoRefresh: Bool

    /// Initializes a configuration object
    ///
    /// The configuration will include these headers as default: App-Version, UBFoundation-Version, OS-Version.
    /// In addition all the additional headers you pass in the sessionConfiguration object. If one of the headers is found in the sessionConfiguration object then the sessionConfiguration has priority.
    ///
    /// - Parameters:
    ///   - sessionConfiguration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, credential storage, and so on.
    ///   - hostsServerTrusts: A dictionary of Hosts (keys) and their corresponding evaluator. It is highly recommended that you configure for each possible host an evaluator then MITM attacks will be nearly impossible.
    ///   - defaultServerTrust: A evaluator to use in case no matche is found in the list of hosts. If no default is set and the host is not found then the default OS behaviour is executed.
    ///   - allowRedirections: Set this flag to `false` if you do not want any redirection. If response wants to redirect, and the flag is set to false, the redirection will not happpen and the data task will be called with the response that caused the redirection.
    ///   - allowAutoRefresh: If set to true and the response has the correct headers. Then the session will try to refresh the data once the cached data is invalid or the next update time is reached.
    public init(sessionConfiguration: URLSessionConfiguration = .default, hostsServerTrusts: [String: ServerTrustEvaluator] = [:], defaultServerTrust: ServerTrustEvaluator? = nil, allowRedirections: Bool = true, allowAutoRefresh: Bool = true) {
        self.sessionConfiguration = sessionConfiguration.copy() as! URLSessionConfiguration
        self.hostsServerTrusts = hostsServerTrusts
        self.defaultServerTrust = defaultServerTrust
        self.allowRedirections = allowRedirections
        self.allowAutoRefresh = allowAutoRefresh

        applyDefaultHeaders(configuration: sessionConfiguration)
    }

    private func applyDefaultHeaders(configuration: URLSessionConfiguration) {
        var headers: [AnyHashable: Any] = [:]

        // Add encoding
        headers[HTTPHeaderField.StandardKeys.acceptEncoding.rawValue] = "gzip"

        // Add app information
        if let info = Bundle.main.infoDictionary,
            let appName = info[kCFBundleNameKey as String] as? String {
            let shortVersionNumber = info["CFBundleShortVersionString"] as? String
            let buildNumber = info[kCFBundleVersionKey as String] as? String
            headers["App-Version"] = "\(appName) v\(shortVersionNumber ?? "unknown") (\(buildNumber ?? "unknown"))"
        }

        // Add framework information
        if let info = Bundle(for: UBURLSessionConfiguration.self).infoDictionary {
            let shortVersionNumber = info["CFBundleShortVersionString"] as? String
            let buildNumber = info[kCFBundleVersionKey as String] as? String
            headers["UBFoundation-Version"] = "v\(shortVersionNumber ?? "unknown") (\(buildNumber ?? "unknown"))"
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
        #endif
        
        
        if let configHeaders = configuration.httpAdditionalHeaders {
            for header in configHeaders {
                headers[header.key] = header.value
            }
        }

        configuration.httpAdditionalHeaders = headers
    }
}
