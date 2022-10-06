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
    public struct Options {
        var useOwnNavigationView: Bool
        var additionalUserDefaults: [(defaults: UserDefaults, displayName: String)]

        public init(useOwnNavigationView: Bool = true, additionalUserDefaults: [(defaults: UserDefaults, displayName: String)] = []) {
            self.useOwnNavigationView = useOwnNavigationView
            self.additionalUserDefaults = additionalUserDefaults
        }
    }

    static var isActivated : Bool = false
    static var options: Options = .init()

    private static let devTools : [DevTool.Type] = [FingerTipsDevTools.self, LocalizationDevTools.self, UIViewDevTools.self]

    public static func setup(options: Options = .init()) {
        Self.isActivated = true
        Self.options = options

        for d in devTools {
            d.setup()
        }
    }
}
