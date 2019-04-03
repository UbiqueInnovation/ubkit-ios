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

    /// Initializes a configuration object
    ///
    /// - Parameters:
    ///   - sessionConfiguration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, credential storage, and so on.
    ///   - hostsServerTrusts: A dictionary of Hosts (keys) and their corresponding evaluator. It is highly recommended that you configure for each possible host an evaluator then MITM attacks will be nearly impossible.
    ///   - defaultServerTrust: A evaluator to use in case no matche is found in the list of hosts. If no default is set and the host is not found then the default OS behaviour is executed.
    ///   - allowRedirections: Set this flag to `false` if you do not want any redirection. If response wants to redirect, and the flag is set to false, the redirection will not happpen and the data task will be called with the response that caused the redirection.
    public init(sessionConfiguration: URLSessionConfiguration = .default, hostsServerTrusts: [String: ServerTrustEvaluator] = [:], defaultServerTrust: ServerTrustEvaluator? = nil, allowRedirections: Bool = true) {
        self.sessionConfiguration = sessionConfiguration.copy() as! URLSessionConfiguration
        self.hostsServerTrusts = hostsServerTrusts
        self.defaultServerTrust = defaultServerTrust
        self.allowRedirections = allowRedirections
    }
}
