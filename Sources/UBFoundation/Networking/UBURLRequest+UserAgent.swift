//
//  UBURLRequest+UserAgent.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 10.06.20.
//

import Foundation

#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#elseif os(macOS)
    import AppKit
#endif

extension UBURLRequest {
    @MainActor
    public mutating func setDefaultUserAgent() {
        setHTTPHeaderField(UBHTTPHeaderField(key: .userAgent, value: UBURLRequest.userAgent))
    }

    @MainActor
    static var userAgent: String {
        let bundleId = Bundle.bundleId
        let appVersion = Bundle.appVersion
        let os = "iOS"

        let systemVersion: String
        #if os(iOS) || os(tvOS)
            systemVersion = UIDevice.current.systemVersion
        #elseif os(watchOS)
            systemVersion = WKInterfaceDevice.current().systemVersion
        #elseif os(macOS)
            let osv = ProcessInfo.processInfo.operatingSystemVersion
            systemVersion = "macOS \(osv.majorVersion).\(osv.minorVersion).\(osv.patchVersion)"
        #elseif os(visionOS)
            let osv = ProcessInfo.processInfo.operatingSystemVersion
            systemVersion = "visionOS \(osv.majorVersion).\(osv.minorVersion).\(osv.patchVersion)"
        #endif

        let header = [bundleId, appVersion, os, systemVersion].joined(separator: ";")
        return header
    }
}
