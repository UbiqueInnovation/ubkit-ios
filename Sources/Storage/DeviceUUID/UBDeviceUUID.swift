//
//  DeviceUUID.swift
//  UBFoundation iOS
//
//  Created by Nicolas Märki on 29.03.20.
//

import Foundation

public struct UBDeviceUUID {
    public static func getUUID() -> String {
        if let uuid = keychainDeviecUUID {
            return uuid
        } else {
            let uuid = UUID().uuidString
            keychainDeviecUUID = uuid
            return uuid
        }
    }

    /// The push token UUID for this device stored in the Keychain
    @UBKeychainStored(key: "UBDeviceUUID", accessibility: .whenUnlockedThisDeviceOnly)
    private static var keychainDeviecUUID: String?
}
