//
//  DevToolsView.swift
//  UBDevTools
//
//  Created by Marco Zimmermann on 30.09.22.
//

import SwiftUI
import UBFoundation
import UIKit

public class DevToolsViewController: UIHostingController<DevToolsView> {
    // MARK: - Init

    public init?() {
        guard UBDevTools.isActivated, let dtv = DevToolsView() else { return nil }
        super.init(rootView: dtv)
    }

    // MARK: - Init?

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct DevToolsView: View {
    @State private var showingKeychainDeleteAlert = false
    @State private var showingUserDefaultsDeleteAlert = false

    @StateObject private var viewModel = BackendDevTools.viewModel

    @State private var cacheUpdateValue = UUID()

    // MARK: - Init

    public init?() {
        guard UBDevTools.isActivated else { return nil }
    }

    private var contentView: some View {
        Form {
            viewModel.appSpecificView
            Group {
                Section(header: Text("UserDefaults.standard")) {
                    Button("Clear UserDefaults.standard") {
                        showingUserDefaultsDeleteAlert = true
                    }
                    .alert(isPresented: $showingUserDefaultsDeleteAlert) {
                        Alert(
                            title: Text("Delete"),
                            message: Text("Are you sure?"),
                            primaryButton: .destructive(
                                Text("Delete"),
                                action: {
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
                        }
                        .alert(isPresented: $showingUserDefaultsDeleteAlert) {
                            Alert(
                                title: Text("Delete"),
                                message: Text("Are you sure?"),
                                primaryButton: .destructive(
                                    Text("Delete"),
                                    action: {
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
                    }
                    .alert(isPresented: $showingKeychainDeleteAlert) {
                        Alert(
                            title: Text("Delete"),
                            message: Text("Are you sure?"),
                            primaryButton: .destructive(
                                Text("Delete"),
                                action: {
                                    UBKeychain().deleteAllItems()
                                }),
                            secondaryButton: .cancel(Text("Cancel"), action: {})
                        )
                    }
                    NavigationLink("Editor") {
                        KeychainEditor()
                    }
                }
            }
            Section(header: Text("Caches")) {
                Button("Clear all") {
                    for cache in CacheDevTools.caches {
                        CacheDevTools.clearCache(cache.id)
                    }
                    cacheUpdateValue = UUID()
                }
                ForEach(CacheDevTools.caches, id: \.id) { cache in
                    VStack(alignment: .leading) {
                        Text(cache.id).bold()
                        Text(CacheDevTools.currentSizes(cache.id, updateValue: cacheUpdateValue))
                        Button("Clear") {
                            CacheDevTools.clearCache(cache.id)
                            cacheUpdateValue = UUID()
                        }
                    }
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
                if viewModel.urls.count > 0 {
                    List(viewModel.urls, id: \.title) { bu in
                        BackendUrlEditor(url: bu)
                    }
                    Button {
                        BackendDevTools.resetAllUrls()
                    } label: {
                        Text("Reset all URLs")
                    }

                } else {
                    Text("No backend urls configured.")
                }
            }
            Section(header: Text("Map")) {
                Toggle("Raster tiles debug overlay", isOn: Binding(get: { Self.mapRasterTilesDebugOverlay }, set: { Self.mapRasterTilesDebugOverlay = $0 }))
                Button("Remove all map-related cached responses") {
                    let cache = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024, diskPath: "ch.openmobilemaps.urlcache")
                    CacheDevTools.clearCache(cache)
                }
            }
            Section(header: Text("Proxy settings")) {
                Toggle(
                    "Start Proxy for today",
                    isOn: Binding(
                        get: {
                            guard Self.enableNetworkingProxySettings, let enabledDate = Self.proxyEnabledDate else { return false }
                            return Calendar.current.isDateInToday(enabledDate)
                        },
                        set: {
                            Self.enableNetworkingProxySettings = $0
                            Self.proxyEnabledDate = $0 ? Date() : nil
                        }
                    ))
                TextField("Host", text: Binding(get: { Self.proxySettingsHost ?? "" }, set: { Self.proxySettingsHost = $0 }))
                TextField(
                    "Port",
                    text: Binding(
                        get: {
                            Self.proxySettingsPort != nil ? String(Self.proxySettingsPort!) : ""
                        },
                        set: {
                            Self.proxySettingsPort = Int($0)
                        }))
            }

            #if !targetEnvironment(simulator)
                ShareDocumentsView()
            #endif

            if #available(iOS 15.0, *) {
                LogDevToolsView()
            }
        }
    }

    // MARK: - Body

    public var body: some View {
        NavigationView {
            contentView
                .navigationTitle("DevTools")
                .toolbar {
                    Button("Save and exit") {
                        exit(0)
                    }
                }
        }
    }

    // MARK: - State handling

    @UBUserDefault(key: "ubkit.devtools.fingertips.key", defaultValue: false)
    public static var showFingerTips: Bool

    @UBUserDefault(key: "ubkit.devtools.showlocalizationkeys.key", defaultValue: false)
    public static var showLocalizationKeys: Bool

    @UBUserDefault(key: "ubkit.devtools.uiviewbordertools.key", defaultValue: false)
    public static var showViewBorders: Bool

    @UBUserDefault(key: "io.openmobilemaps.debug.rastertiles.enabled", defaultValue: false)
    public static var mapRasterTilesDebugOverlay: Bool

    @UBUserDefault(key: "ubkit.devtools.proxy.enabled.key", defaultValue: false)
    static var enableNetworkingProxySettings: Bool

    @UBUserDefault(key: "ubkit.devtools.proxy.enabled.date.key", defaultValue: nil)
    private static var proxyEnabledDate: Date?

    @UBUserDefault(key: "ubkit.devtools.proxy.host.key", defaultValue: nil)
    static var proxySettingsHost: String?

    @UBUserDefault(key: "ubkit.devtools.proxy.port.key", defaultValue: nil)
    static var proxySettingsPort: Int?
}
