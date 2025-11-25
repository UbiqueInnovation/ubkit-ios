//
//  UserDefaultsEditor.swift
//
//
//  Created by Stefan Mitterrutzner on 03.10.22.
//

import Foundation
import SwiftUI

@MainActor
class ObservableUserDefaults: ObservableObject {
    let userDefaults: UserDefaults

    var observer: Any?

    var dictionary: [String: Any] = [:]
    var keys: [String] = []

    @Published var searchText: String = "" {
        didSet {
            reload()
        }
    }

    var filterKeys: Bool = true {
        didSet {
            reload()
        }
    }

    static let systemKeys: [String] = [
        "AKDeviceUnlockState",
        "AKLastCheckInAttemptDate",
        "AKLastCheckInSuccessDate",
        "AKLastEmailListRequestDateKey",
        "AKLastIDMSEnvironment",
        "AddingEmojiKeybordHandled",
        "AppleITunesStoreItemKinds",
        "AppleKeyboards",
        "AppleKeyboardsExpanded",
        "AppleLanguages",
        "AppleLanguagesDidMigrate",
        "AppleLanguagesSchemaVersion",
        "AppleLocale",
        "ApplePasscodeKeyboards",
        "ApplePerAppLanguageSelectionBundleIdentifiers",
        "AppleTemperatureUnit",
        "AppleTextDirection",
        "CarCapabilities",
        "INNextDelayedOfferFailsafeDateKey",
        "INNextFreshmintRefreshDateKey",
        "INNextHearbeatDate",
        "METAL_DEBUG_ERROR_MODE",
        "METAL_DEVICE_WRAPPER_TYPE",
        "METAL_ERROR_CHECK_EXTENDED_MODE",
        "METAL_ERROR_MODE",
        "METAL_WARNING_MODE",
        "MPDebugEUVolumeLimit",
        "MSVLoggingMasterSwitchEnabledKey",
        "NSAllowsDefaultLineBreakStrategy",
        "NSInterfaceStyle",
        "NSLanguages",
        "NSPersonNameDefaultShortNameFormat",
        "NSVisualBidiSelectionEnabled",
        "PKContactlessInterfaceHomeButtonSourceHasOccuredKey",
        "PKEnableStockholmSettings",
        "PKKeychainVersionKey",
        "PKLogNotificationServiceResponsesKey",
        "TVRCDeviceIdentifierKey",
        "TVRCDeviceTimeoutKey",
        "TVRCMostRecentlyConnectedIDKey",
        "WebKitShowLinkPreviews",
        "com.apple.Animoji.StickerRecents.SplashVersion",
        "com.apple.content-rating.AppRating",
        "com.apple.content-rating.ExplicitBooksAllowed",
        "com.apple.content-rating.ExplicitMusicPodcastsAllowed",
        "com.apple.content-rating.MovieRating",
        "com.apple.content-rating.TVShowRating",
        "ActivePrototypingEnabled",
        "ClearPrototypeCachesForMigration",
        "ClearSettingsArchivesForMigration",
        "MultiWindowEnabled",
        "PrototypeSettingsEnabled",
        "RemotePrototypingEnabled",
        "RingerButtonShowsUI",
        "RingerSwitchShowsUI",
        "VolumeDownShowsUI",
        "VolumeUpShowsUI",
    ]

    static let systemKeyPrefixes: [String] = [
        "Apple",
        "NS",
        "PK",
        "Web",
        "com.apple",
        "INNext",
        "METAL",
        "AK",
        "TestRecipe",
    ]

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        reload()
        observer = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.reload()
            }
        }
    }

    func reload() {
        let temp = userDefaults.dictionaryRepresentation()
            .filter { el in
                if filterKeys {
                    if Self.systemKeys.contains(el.key) { return false }
                    for prefix in Self.systemKeyPrefixes {
                        if el.key.hasPrefix(prefix) { return false }
                    }
                }
                if !searchText.isEmpty {
                    return el.key.localizedCaseInsensitiveContains(searchText)
                }
                return true
            }
        self.dictionary = temp
        self.keys = Array(dictionary.keys).sorted()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

public struct UserDefaultsEditor: View {
    let userDefaults: UserDefaults
    let displayName: String
    @ObservedObject var store: ObservableUserDefaults

    public init(userDefaults: UserDefaults, displayName: String = "UserDefaults Editor") {
        self.userDefaults = userDefaults
        self.displayName = displayName
        self.store = ObservableUserDefaults(userDefaults: userDefaults)
    }

    public var body: some View {
        Form {
            Section(header: Text(displayName)) {
                if #available(iOS 15.0, *) {
                    // Search is handled by .searchable modifier
                } else {
                    TextField("Search", text: $store.searchText)
                }
                Toggle(isOn: $store.filterKeys) {
                    Text("Filter System Defaults")
                }
            }
            Section {
                ForEach(store.keys, id: \.self) { key in
                    UserDefaultsRowView(key: key, value: store.dictionary[key], userDefaults: userDefaults)
                        .deleteDisabled(ObservableUserDefaults.systemKeys.contains(key))
                }
                .onDelete { indexSet in
                    guard let firstIndex = indexSet.first else { return }
                    userDefaults.removeObject(forKey: store.keys[firstIndex])
                }
            }
        }
        .navigationBarTitle(Text(displayName))
        .modifier(SearchableModifier(text: $store.searchText))
    }
}

struct SearchableModifier: ViewModifier {
    @Binding var text: String

    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.searchable(text: $text)
        } else {
            content
        }
    }
}

struct UserDefaultsRowView: View {
    let key: String
    let value: Any?
    let userDefaults: UserDefaults

    private var typeInfo: (icon: String, color: Color, typeName: String) {
        switch value {
            case is String: return ("text.quote", .blue, "String")
            case is Bool: return ("switch.2", .green, "Bool")
            case is Int: return ("number", .orange, "Int")
            case is Double: return ("number.circle", .orange, "Double")
            case is Date: return ("calendar", .red, "Date")
            case is Data: return ("doc.text.fill", .purple, "Data")
            default: return ("questionmark.circle", .gray, "Unknown")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: typeInfo.icon)
                    .foregroundColor(typeInfo.color)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 20)

                Text(key)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(typeInfo.typeName)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(typeInfo.color.opacity(0.1))
                    .foregroundColor(typeInfo.color)
                    .cornerRadius(4)
            }

            if let value = value {
                Group {
                    switch value {
                        case let value as Date:
                            DatePicker(
                                selection: Binding(
                                    get: { value },
                                    set: { userDefaults.set($0, forKey: key) }
                                )
                            ) {
                                EmptyView()
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        case let value as Bool:
                            Toggle(
                                isOn: Binding(
                                    get: { value },
                                    set: { userDefaults.set($0, forKey: key) }
                                )
                            ) {
                                Text(value ? "True" : "False")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                        case let value as String:
                            TextField(
                                "Value",
                                text: Binding(
                                    get: { value },
                                    set: { userDefaults.set($0, forKey: key) }
                                )
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(.body, design: .monospaced))

                        case let value as Double:
                            TextField(
                                "Value",
                                text: Binding(
                                    get: { "\(value)" },
                                    set: { userDefaults.setValue(Double($0), forKey: key) }
                                )
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .font(.system(.body, design: .monospaced))

                        case let value as Int:
                            TextField(
                                "Value",
                                text: Binding(
                                    get: { "\(value)" },
                                    set: { userDefaults.setValue(Int($0), forKey: key) }
                                )
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .keyboardType(.numberPad)
                            .font(.system(.body, design: .monospaced))

                        case let value as Data:
                            TextField(
                                "Value",
                                text: Binding(
                                    get: { value.base64EncodedString() },
                                    set: { userDefaults.setValue(Data(base64Encoded: $0), forKey: key) }
                                )
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)

                        default:
                            if let value = value as? CustomDebugStringConvertible {
                                Text(value.debugDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Unsupported Type")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                    }
                }
                .padding(10)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 6)
    }
}
