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
            Section(header: Text("User Defaults")) {
                Button("Clear UserDefaults") {
                    showingUserDefaultsDeleteAlert = true
                }.alert(isPresented: $showingUserDefaultsDeleteAlert) {
                    Alert(
                        title: Text("Delete"),
                        message: Text("Are you sure?"),
                        primaryButton: .destructive(Text("Delete"), action: {
                            UserDefaultsDevTools.clearUserDefaults()
                        }),
                        secondaryButton: .cancel(Text("Cancel"), action: {})
                    )
                }

                NavigationLink("Editor") {
                    UserDefaultsEditor()
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
            Section(header: Text("Map")) {
                Toggle("Raster tiles debug overlay", isOn: Binding(get: { Self.mapRasterTilesDebugOverlay }, set: { Self.mapRasterTilesDebugOverlay = $0 }))
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

    @UBUserDefault(key: "io.openmobilemaps.debug.rastertiles.enabled", defaultValue: false)
    public static var mapRasterTilesDebugOverlay: Bool

    @State var cacheSizeText : String = CacheDevTools.currentSizes(URLCache.shared)
}

