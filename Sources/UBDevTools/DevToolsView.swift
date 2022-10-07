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
    @State private var showingKeychainDeleteAlert = false
    @State private var showingUserDefaultsDeleteAlert = false

    // MARK: - Init

    public init?() {
        guard UBDevTools.isActivated else { return nil }
    }

    private var contentView : some View {
        Form {
            Section(header: Text("UserDefaults.standard")) {
                Button("Clear UserDefaults.standard") {
                    showingUserDefaultsDeleteAlert = true
                }.alert(isPresented: $showingUserDefaultsDeleteAlert) {
                    Alert(
                        title: Text("Delete"),
                        message: Text("Are you sure?"),
                        primaryButton: .destructive(Text("Delete"), action: {
                            UserDefaultsDevTools.clearUserDefaults(.standard)
                        }),
                        secondaryButton: .cancel(Text("Cancel"), action: {})
                    )
                }
                NavigationLink("Editor") {
                    UserDefaultsEditor(userDefaults: .standard, displayName: "UserDefaults.standard", store: ObservableUserDefaults(userDefaults: .standard))
                }
            }

            Section(header: Text("Shared UserDefaults")) {
                if let shared = UserDefaultsDevTools.sharedUserDefaults {
                    Button("Clear Shared UserDefaults") {
                        showingUserDefaultsDeleteAlert = true
                    }.alert(isPresented: $showingUserDefaultsDeleteAlert) {
                        Alert(
                            title: Text("Delete"),
                            message: Text("Are you sure?"),
                            primaryButton: .destructive(Text("Delete"), action: {
                                UserDefaultsDevTools.clearUserDefaults(shared)
                            }),
                            secondaryButton: .cancel(Text("Cancel"), action: {})
                        )
                    }
                    NavigationLink("Editor") {
                        UserDefaultsEditor(userDefaults: shared, displayName: "Shared UserDefaults", store: ObservableUserDefaults(userDefaults: shared))
                    }
                } else {
                    Text("No Shared UserDefaults configured.")
                }
            }
            Section(header: Text("Keychain")) {
                Button("Clear Keychain") {
                    showingKeychainDeleteAlert = true
                }.alert(isPresented: $showingKeychainDeleteAlert) {
                    Alert(
                        title: Text("Delete"),
                        message: Text("Are you sure?"),
                        primaryButton: .destructive(Text("Delete"), action: {
                            UBKeychain().deleteAllItems()
                        }),
                        secondaryButton: .cancel(Text("Cancel"), action: {})
                    )
                }
                NavigationLink("Editor") {
                    KeychainEditor()
                }
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
            Section(header: Text("Map")) {
                Toggle("Raster tiles debug overlay", isOn: Binding(get: { Self.mapRasterTilesDebugOverlay }, set: { Self.mapRasterTilesDebugOverlay = $0 }))
            }
            if #available(iOS 15.0, *) {
                LogDevToolsView()
            }
        }
    }

    // MARK: - Body

    public var body : some View {
        NavigationView {
            if #available(iOS 14.0, *) {
                contentView
                    .navigationTitle("DevTools")
                    .toolbar {
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

    @UBUserDefault(key: "io.openmobilemaps.debug.rastertiles.enabled", defaultValue: false)
    public static var mapRasterTilesDebugOverlay: Bool

    @State var cacheSizeText : String = CacheDevTools.currentSizes(URLCache.shared)
}

