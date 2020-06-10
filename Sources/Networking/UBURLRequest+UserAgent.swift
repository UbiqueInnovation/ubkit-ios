//
//  UBURLRequest+UserAgent.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 10.06.20.
//

import UIKit

extension UBURLRequest {

    public mutating func setDefaultUserAgent() {
        setHTTPHeaderField(UBHTTPHeaderField(key: .userAgent, value: UBURLRequest.userAgent))
    }

    static var userAgent: String {
        let bundleId = Bundle.bundleId
        let appVersion = Bundle.appVersion
        let os = "iOS"
        let systemVersion = UIDevice.current.systemVersion
        let header = [bundleId, appVersion, os, systemVersion].joined(separator: ";")
        return header
    }
}
