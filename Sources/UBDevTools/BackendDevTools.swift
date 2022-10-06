//
//  BackendDevTools.swift
//  
//
//  Created by Marco Zimmermann on 04.10.22.
//

import Foundation

public struct BaseUrl {
    public init(title: String, url: String) {
        self.title = title
        self.url = url
    }
    
    let title: String
    let url: String
}

class BackendDevTools : DevTool {
    private static var didSwizzle = false
    public static var baseUrls: [BaseUrl] = []

    public static func setup() {}

    public static func setup(baseUrls: [BaseUrl]) {
        Self.baseUrls = baseUrls

        for b in baseUrls {
            if UserDefaults.standard.string(forKey: Self.key(b)) != nil {
                Self.startSwizzling()
                break
            }
        }
    }

    public static func saveNewUrl(baseUrl: BaseUrl, newUrl: String) {
        let key = Self.key(baseUrl)
        UserDefaults.standard.set(newUrl, forKey: key)

        Self.startSwizzling()
    }

    public static func currentUrlString(baseUrl: BaseUrl) -> String {
        return UserDefaults.standard.string(forKey: key(baseUrl)) ?? baseUrl.url
    }

    public static func key(_ b: BaseUrl) -> String {
        return "ubkit.devtools.backenddevtools." + b.url
    }

    private static func keyPrefix() -> String {
        return "ubkit.devtools.backenddevtools."
    }

    private static func startSwizzling() {
        NSURL.initSwizzleWizzle()
    }
}

private extension NSURL {
    private static var didSwizzle = false

    static func initSwizzleWizzle() {
        guard !self.didSwizzle else { return }

        let initSelector = (#selector(NSURL.init(string:relativeTo:)), #selector(swizzled_init(string:relativeTo:)))
        let initSelector2 = (#selector(NSURL.init(string:)), #selector(swizzled_init(string:)))

        for i in [initSelector, initSelector2] {
            guard let originalMethod = class_getInstanceMethod(NSURL.self, i.0),
                  let swizzledMethod = class_getInstanceMethod(NSURL.self, i.1)
            else { return }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

        Self.didSwizzle = true
    }

    @objc func swizzled_init(string: String, relativeTo: NSURL?) -> NSURL? {
        let changed = changedUrl(string)
        return self.swizzled_init(string: changed ?? string, relativeTo: relativeTo)
    }

    @objc func swizzled_init(string: String) -> NSURL? {
        let changed = changedUrl(string)
        return self.swizzled_init(string: changed ?? string)
    }

    // MARK: - Exchange implementations

    private func changedUrl(_ string: String) -> String? {
        for b in BackendDevTools.baseUrls {
            let alternative = BackendDevTools.currentUrlString(baseUrl: b)
            let rep = b.url.replacingOccurrences(of: "//", with: "/")

            if string.contains(b.url) || string.contains(rep) {
                return string.replacingOccurrences(of: b.url, with: alternative).replacingOccurrences(of: rep, with: alternative)
            }
        }

        return nil
    }
}
