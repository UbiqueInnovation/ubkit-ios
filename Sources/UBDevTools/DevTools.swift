//
//  DevTools.swift
//  
//
//  Created by Marco Zimmermann on 03.10.22.
//

import Foundation

protocol DevTool {
    static func setup()
}

@available(iOS 13.0, *)
class DevTools {
    static var isActivated : Bool = false

    static private let devTools : [DevTool.Type] = [FingerTipsDevTools.self, LocalizationDevTools.self]

    static func setup() {
        self.isActivated = true

        for d in devTools {
            d.setup()
        }
    }
}
