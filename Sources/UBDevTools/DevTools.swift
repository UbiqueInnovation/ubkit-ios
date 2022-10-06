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
public class UBDevTools {
    static var isActivated : Bool = false

    private static let devTools : [DevTool.Type] = [FingerTipsDevTools.self, LocalizationDevTools.self, UIViewDevTools.self]

    public static func setup() {
        self.isActivated = true

        for d in devTools {
            d.setup()
        }
    }

    public static func setupBaseUrls(baseUrls: [BaseUrl]) {
        BackendDevTools.setup(baseUrls: baseUrls)
    }
}
