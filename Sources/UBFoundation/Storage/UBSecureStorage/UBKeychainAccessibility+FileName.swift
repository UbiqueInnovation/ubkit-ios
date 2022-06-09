//
//  UBKeychainAccessibility+FileName.swift
//
//
//  Created by Stefan Mitterrutzner on 09.06.22.
//

import Foundation

extension UBKeychainAccessibility {
    var secureStorageFileName: String {
        switch self {
            case .whenUnlocked:
                return "wu"
            case .afterFirstUnlock:
                return "afu"
            case .always:
                return "a"
            case .whenPasscodeSetThisDeviceOnly:
                return "wpstdo"
            case .whenUnlockedThisDeviceOnly:
                return "wutdo"
            case .afterFirstUnlockThisDeviceOnly:
                return "afutdo"
            case .alwaysThisDeviceOnly:
                return "atdo"
        }
    }
}
