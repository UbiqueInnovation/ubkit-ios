//
//  UserDefaultsEditor.swift
//
//
//  Created by Stefan Mitterrutzner on 03.10.22.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation
import SwiftUI
import UBFoundation

@available(iOS 13.0, *)
class ObservableKeychainEditor: ObservableObject {
    var dictionary: [String: String] = [:]
    var keys: [String] = []

    init() {
        reload()
    }

    func reload() {
        let temp = getAllKeyChainItems()
        self.dictionary = temp
        self.keys = Array(dictionary.keys).sorted()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    private func getAllKeyChainItems() -> [String: String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecReturnRef as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var result: AnyObject?

        let lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        var values = [String: String]()
        if lastResultCode == noErr {
            let array = result as? [[String: Any]]

            for item in array! {
                if let key = item[kSecAttrAccount as String] as? String,
                   let value = item[kSecValueData as String] as? Data,
                   let object = try? JSONDecoder().decode(String.self, from: value) {
                    values[key] = object
                }
            }
        }

        return values
    }
}

@available(iOS 13.0, *)
public struct KeychainEditor: View {
    @ObservedObject var store = ObservableKeychainEditor()

    public var body: some View {
        Form {
            Section {
                ForEach(store.keys, id: \.self) { key in
                    VStack(alignment: .leading) {
                        Text("Key: \(key)").font(.caption)
                        if let value = store.dictionary[key] {
                            TextField("", text: Binding(
                                get: {
                                    value
                                },
                                set: {
                                    UBKeychain().set($0, for: UBKeychainKey<String>(key), accessibility: .whenUnlocked)
                                    store.reload()
                                }
                            )).textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }.onDelete { indexSet in
                    guard let firstIndex = indexSet.first else { return }
                    let key = store.keys[firstIndex]
                    UBKeychain().delete(for: UBKeychainKey<String>(key))
                    store.reload()
                }
            }
        }.navigationBarTitle(Text("Keychain Editor"))
    }
}
#endif
