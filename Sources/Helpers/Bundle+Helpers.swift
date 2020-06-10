//
//  Bundle+Helpers.swift
//  UBFoundation
//
//  Created by Zeno Koller on 10.06.20.
//

import Foundation

public extension Bundle {
    static var bundleId: String {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    }

    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }

    static var buildNumber: String {
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

        // We take the last component because the CI service prepends build numbers with the date and time
        return buildNumber.components(separatedBy: ".").last ?? buildNumber
    }
}
