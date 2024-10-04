//
//  UBDeviceUUID.swift
//  UBFoundation iOS
//
//  Created by Nicolas Märki on 29.03.20.
//

import Foundation

@MainActor
public enum UBDeviceUUID {
    public static func getUUID() -> String {
        if let uuid = keychainDeviceUUID {
            return uuid
        } else {
            let uuid = UUID().uuidString
            keychainDeviceUUID = uuid
            return uuid
        }
    }

    /// The push token UUID for this device stored in the Keychain
    @UBKeychainStored(key: "UBDeviceUUID", defaultValue: nil, accessibility: .whenUnlockedThisDeviceOnly)
    private static var keychainDeviceUUID: String?
}
