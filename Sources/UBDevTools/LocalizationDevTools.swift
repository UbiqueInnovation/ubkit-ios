//
//  LocalizationDevTools.swift
//  
//
//  Created by Marco Zimmermann on 03.10.22.
//

import Foundation
import UIKit
import UBFoundation

class LocalizationDevTools : DevTool {
    static func setup() {

    }

    static func showLocalizationKeys(_ showLocalizationKeys: Bool) {
        Bundle.localizationKeySwizzleWizzle()

        if showLocalizationKeys {
        } else {

        }
    }

    @UBUserDefault(key: "ubkit.devtools.localizationdevtools.key", defaultValue: false)
    static var showLocalizationKeysOn: Bool
}

public extension Bundle {

    static var localizationKeySwizzled = false

    static func localizationKeySwizzleWizzle() {
        guard let originalMethod = class_getInstanceMethod(Bundle.self, #selector(localizedString(forKey:value:table:))), let swizzledMethod = class_getInstanceMethod(Bundle.self, #selector(specialLocalizedString(forKey:value:table:))), !Self.localizationKeySwizzled
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
        Self.localizationKeySwizzled = true
    }

    @objc func specialLocalizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        return key
    }



}
