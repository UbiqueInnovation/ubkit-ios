//
//  DeviceUUID.swift
//  UBFoundation iOS
//
//  Created by Nicolas Märki on 29.03.20.
//

import Foundation

public struct UBDeviceUUID {
    public enum Storage {
        case userDefaults
    }

    public static func getUUID(storage: Storage) -> String {
        switch storage {
        case .userDefaults:
            if let uuid = userDefaultsDeviceUUID {
                return uuid
            } else {
                let uuid = UUID().uuidString
                userDefaultsDeviceUUID = uuid
                return uuid
            }
        }
    }

    /// The push token UUID for this device
    @UBOptionalUserDefault(key: "UBDeviceUUID")
    private static var userDefaultsDeviceUUID: String?
}
