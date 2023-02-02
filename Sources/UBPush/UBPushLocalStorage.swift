//
//  UBPushLocalStorage.swift
//  UBFoundationPush
//
//  Created by Zeno Koller on 25.03.20.
//  Copyright © 2020 Ubique Apps & Technology. All rights reserved.
//

import UBFoundation
import UIKit
import Foundation

public protocol UBPushRegistrationLocalStorage {
    /// The push token obtained from Apple
    var pushToken: String? { get set }

    /// Is the push token still valid?
    var isValid: Bool { get set }

    /// The last registration date for this service of the current push token
    var lastRegistrationDate: Date? { get set }
}

struct UBPushRegistrationStandardLocalStorage: UBPushRegistrationLocalStorage {
    static var shared = UBPushRegistrationStandardLocalStorage()

    /// The push token obtained from Apple
    @UBUserDefault(key: "UBPushRegistrationManager_Token", defaultValue: nil)
    var pushToken: String?

    /// Is the push token still valid?
    @UBUserDefault(key: "UBPushRegistrationManager_IsValid", defaultValue: false)
    var isValid: Bool

    /// The last registration date on our backend for this service of the current push token
    @UBUserDefault(key: "UBPushRegistrationManager_LastRegistrationDate", defaultValue: nil)
    var lastRegistrationDate: Date?
}
