//
//  BackendDevTools.swift
//
//
//  Created by Marco Zimmermann on 04.10.22.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public class BaseUrl: ObservableObject {
    let title: String
    let url: String
    @Published var currentUrl: String

    public init(title: String, url: String) {
        self.title = title
        self.url = url
        self.currentUrl = BackendDevTools.currentUrlString(url: url)
    }
}

@available(iOS 13.0, *)
class BackendDevTools: DevTool {
    private static var didSwizzle = false
    public static var baseUrls: [BaseUrl] = []

    class ViewModel: ObservableObject {
        @Published var urls: [BaseUrl] = []
    }

    public static var viewModel = ViewModel()

    public static func setup() {}

    public static func setup(baseUrls: [BaseUrl]) {
        Self.baseUrls = baseUrls

        for b in baseUrls {
            if UserDefaults.standard.string(forKey: Self.key(url: b.url)) != nil {
                Self.startSwizzling()
                break
            }
        }

        Self.viewModel.urls = baseUrls
    }

    public static func saveNewUrl(baseUrl: BaseUrl, newUrl: String) {
        let key = Self.key(url: baseUrl.url)
        UserDefaults.standard.set(newUrl, forKey: key)

        updateUrls()

        Self.startSwizzling()
    }

    public static func resetAllUrls() {
        for bu in Self.baseUrls {
            UserDefaults.standard.removeObject(forKey: key(url: bu.url))
        }

        updateUrls()
    }

    public static func currentUrlString(url: String) -> String {
        UserDefaults.standard.string(forKey: key(url: url)) ?? url
    }

    private static func updateUrls() {
        for url in Self.viewModel.urls {
            url.currentUrl = Self.currentUrlString(url: url.url)
        }
    }

    public static func key(url: String) -> String {
        keyPrefix() + url
    }

    private static func keyPrefix() -> String {
        "ubkit.devtools.backenddevtools."
    }

    private static func startSwizzling() {
        NSURL.initSwizzleWizzle()
    }
}

@available(iOS 13.0, *)
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
            let alternative = BackendDevTools.currentUrlString(url: b.url)
            let rep = b.url.replacingOccurrences(of: "//", with: "/")

            if string.contains(b.url) || string.contains(rep) {
                return string.replacingOccurrences(of: b.url, with: alternative).replacingOccurrences(of: rep, with: alternative)
            }
        }

        return nil
    }
}
