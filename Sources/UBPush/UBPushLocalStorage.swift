//
//  UBPushLocalStorage.swift
//  UBFoundationPush
//
//  Created by Zeno Koller on 25.03.20.
//  Copyright © 2020 Ubique Apps & Technology. All rights reserved.
//

import UBFoundation
import UIKit


public protocol UBPushRegistrationLocalStorage {
    /// The push token obtained from Apple
    var pushToken: String? { get set }

    /// Is the push token still valid?
    var isValid : Bool { get set }

    /// The last registration date for this service of the current push token
    var lastRegistrationDate: Date? { get set }
}

struct UBPushRegistrationStandardLocalStorage : UBPushRegistrationLocalStorage {
    static var shared = UBPushRegistrationStandardLocalStorage()

    /// The push token obtained from Apple
    @UBOptionalUserDefault(key: "UBPushRegistrationManager_Token")
    var pushToken: String?

    /// Is the push token still valid?
    @UBUserDefault(key: "UBPushRegistrationManager_IsValid", defaultValue: false)
    var isValid: Bool

    /// The last registration date on our backend for this service of the current push token
    @UBOptionalUserDefault(key: "UBPushRegistrationManager_LastRegistrationDate")
    var lastRegistrationDate: Date?
}


