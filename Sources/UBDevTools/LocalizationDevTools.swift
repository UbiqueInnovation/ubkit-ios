//
//  LocalizationDevTools.swift
//
//
//  Created by Marco Zimmermann on 03.10.22.
//

import Foundation
import UBFoundation
import UIKit

@available(iOS 14.0, *)
class LocalizationDevTools: DevTool {
    static func setup() {
        if DevToolsView.showLocalizationKeys {
            Bundle.localizationKeySwizzleWizzle()
        }
    }
}

public extension Bundle {
    @MainActor
    private static var localizationKeySwizzled = false

    @MainActor
    static func localizationKeySwizzleWizzle() {
        guard let originalMethod = class_getInstanceMethod(Bundle.self, #selector(localizedString(forKey:value:table:))), let swizzledMethod = class_getInstanceMethod(Bundle.self, #selector(specialLocalizedString(forKey:value:table:))), !Self.localizationKeySwizzled
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
        Self.localizationKeySwizzled = true
    }

    @MainActor
    @objc func specialLocalizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        key
    }
}
