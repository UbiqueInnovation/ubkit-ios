//
//  DevToolsView.swift
//  UBDevTools
//
//  Created by Marco Zimmermann on 30.09.22.
//

import SwiftUI
import UIKit
import UBFoundation

@available(iOS 13.0, *)
public class DevToolsViewController : UIHostingController<DevToolsView> {
    // MARK: - Init
    
    public init?() {
        guard UBDevTools.isActivated, let dtv = DevToolsView() else { return nil }
        super.init(rootView: dtv)
    }

    // MARK: - Init?

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.0, *)
public struct DevToolsView : View {
    // MARK: - Init

    public init?() {
        guard UBDevTools.isActivated else { return nil }
    }

    private var contentView : some View {
        Form {
            Section(header: Text("User Defaults")) {
                Button("Clear UserDefaults") { UserDefaultsDevTools.clearUserDefaults() }
            }
            Section(header: Text("URLCache.shared")) {
                Text(cacheSizeText)
                Button("Remove all cached responses") {
                    CacheDevTools.clearCache(URLCache.shared)
                    cacheSizeText = CacheDevTools.currentSizes(URLCache.shared)
                }
            }
            Section(header: Text("UIView")) {
                Toggle("Show debug border", isOn: Binding(get: { Self.showViewBorders }, set: { Self.showViewBorders = $0 }))
            }
            Section(header: Text("Finger Tips")) {
                Toggle("Show finger tips", isOn: Binding(get: { Self.showFingerTips }, set: { Self.showFingerTips = $0 }))
            }
            Section(header: Text("Localization")) {
                Toggle("Show localization keys", isOn: Binding(get: { Self.showLocalizationKeys }, set: { Self.showLocalizationKeys = $0 }))
            }

            Section(header: Text("Backend URL Config")) {
                if BackendDevTools.baseUrls.count > 0 {
                    List(BackendDevTools.baseUrls, id: \.title) { bu in
                        VStack(alignment: .leading) {
                            Text(bu.title)
                            TextField(bu.title, text: Binding(get: { BackendDevTools.currentUrlString(baseUrl: bu) },set: { newValue,_ in
                                BackendDevTools.saveNewUrl(baseUrl: bu, newUrl: newValue)
                            }))
                        }
                    }
                } else {
                    Text("No backend urls configured.")
                }
            }
        }
    }

    // MARK: - Body

    public var body : some View {
        NavigationView {
            if #available(iOS 14.0, *) {
                contentView.navigationTitle("DevTools").toolbar {
                    Button("Save and exit") {
                        fatalError()
                    }
                }
            } else {
                contentView
                    .navigationBarTitle(Text("DevTools"))
                    .navigationBarItems(trailing: Button("Save and exit") {
                        fatalError()
                    })
            }
        }
    }

    // MARK: - State handling

    @UBUserDefault(key: "ubkit.devtools.fingertips.key", defaultValue: false)
    public static var showFingerTips: Bool

    @UBUserDefault(key: "ubkit.devtools.showlocalizationkeys.key", defaultValue: false)
    public static var showLocalizationKeys : Bool

    @UBUserDefault(key: "ubkit.devtools.uiviewbordertools.key", defaultValue: false)
    public static var showViewBorders: Bool

    @State var cacheSizeText : String = CacheDevTools.currentSizes(URLCache.shared)
}

