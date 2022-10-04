//
//  UserDefaultsEditor.swift
//  
//
//  Created by Stefan Mitterrutzner on 03.10.22.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
class ObservableUserDefaults: ObservableObject {

    var observer: Any?

    var dictionary: [String: Any] = [:]
    var keys: [String] = []

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
        "com.apple.content-rating.TVShowRating"
    ]

    init(){
        reload()
        observer = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }
            self.reload()
        }
    }

    func reload() {
        let temp = UserDefaults.standard.dictionaryRepresentation().filter { el in
            !filterKeys || !Self.systemKeys.contains(el.key)
        }
        self.dictionary = temp
        self.keys = Array(dictionary.keys).sorted()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

@available(iOS 13.0, *)
public struct UserDefaultsEditor : View {

    @State var filterSystemDefaults: Bool = true

    @ObservedObject var store = ObservableUserDefaults()

    public var body : some View {
        Form {
            Section(header: Text("UserDefaults")) {
                Toggle(isOn: $store.filterKeys) {
                    Text("Filter System Defaults")
                }
            }
            Section {
                ForEach(store.keys, id: \.self) { key in
                    VStack(alignment: .leading) {
                        Text("Key: \(key)").font(.caption)

                        if let value = store.dictionary[key] {

                            switch value {
                                case let value as Date:
                                    DatePicker(selection: Binding(get: {
                                        value
                                    }, set: { newValue in
                                        UserDefaults.standard.set(newValue, forKey: key)
                                    })) {
                                        EmptyView()
                                    }
                                case let value as Bool:
                                    Toggle(isOn: Binding(get: {
                                        value
                                    }, set: { newValue in
                                        UserDefaults.standard.set(newValue, forKey: key)
                                    })) {
                                        EmptyView()
                                    }
                                case let value as String:
                                    TextField("", text: Binding(
                                        get: {
                                            value
                                        },
                                        set: {
                                            UserDefaults.standard.set($0, forKey: key)
                                        }
                                    )).textFieldStyle(RoundedBorderTextFieldStyle())
                                case let value as Double:
                                    TextField("", text: Binding(
                                        get: {
                                            "\(value)"
                                        },
                                        set: {
                                            UserDefaults.standard.setValue(Double($0), forKey: key)
                                        }
                                    ))
                                case let value as Int:
                                    TextField("", text: Binding(
                                        get: {
                                            "\(value)"
                                        },
                                        set: {
                                            UserDefaults.standard.setValue(Int($0), forKey: key)
                                        }
                                    ))
                                case let value as Data:
                                    TextField("", text: Binding(
                                        get: {
                                            "\(value.base64EncodedString())"
                                        },
                                        set: {
                                            UserDefaults.standard.setValue(Data(base64Encoded: $0), forKey: key)
                                        }
                                    ))
                                default:
                                    if let value = value as? CustomDebugStringConvertible {
                                        Text("unsupported Type \n\(value.debugDescription)")
                                    } else {
                                        Text("unsupported Type")
                                    }
                            }
                        }

                    }.deleteDisabled(ObservableUserDefaults.systemKeys.contains(key))
                }.onDelete { indexSet in
                    guard let firstIndex = indexSet.first else { return }
                    UserDefaults.standard.removeObject(forKey: store.keys[firstIndex])
                }
            }
        }.navigationBarTitle(Text("Userdefaults Editor"))
    }
}
