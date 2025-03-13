//
//  UBKeychain.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 31.03.20.
//

import Foundation
import os.log

/// Convenience wrapper for Keychain
public class UBKeychain: UBKeychainProtocol {
    private let logger = Logger(subsystem: "ch.ubique.ubkit", category: "UBKeychain")

    private let encoder: JSONEncoder

    private let decoder: JSONDecoder

    private let accessGroup: String?

    /// Initializer
    /// - Parameters:
    ///   - accessGroup: the sec keychain accessgroup to query in
    ///   https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    ///   Starting with iOS 8 appgroups can be used as accessGroups
    ///   - encoder: a optional custom encoder
    ///   - decoder: a optional custom decoder
    public init(
        accessGroup: String? = nil,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.encoder = encoder
        self.decoder = decoder
        self.accessGroup = accessGroup
    }

    public var identifier: String = "iOS Keychain"
    /// Get a object from the keychain
    /// - Parameter key: a key object with the type
    /// - Returns: a result which either contain the error or the object
    public func get<T: Codable>(for key: UBKeychainKey<T>) -> Result<T, UBKeychainError> {
        var query = self.query(for: key.key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
            case errSecItemNotFound:
                return .failure(.notFound)
            case noErr:
                guard let item = item as? Data else {
                    return .failure(.keychainNotReturningData)
                }
                do {
                    let object = try decoder.decode(T.self, from: item)
                    return .success(object)
                } catch {
                    // fallback for old installations since strings used to be stored utf8 encoded
                    // on next write the value will be written JSON encoded
                    if let stringOpt = String(data: item, encoding: .utf8),
                        let string = stringOpt as? T
                    {
                        return .success(string)
                    }
                    return .failure(.decodingError(error))
                }
            default:
                logger.error("SecItemCopyMatching returned status:\(status, privacy: .public) errorMessage: \(SecCopyErrorMessageString(status, nil) ?? "N/A" as CFString, privacy: .public)")
                return .failure(.cannotAccess(status))
        }
    }

    /// Retrieves data item from the Keychain
    ///
    /// - Parameters:
    ///     - key: The key referring to the value
    /// - Returns: a result which either contain the error or the data
    public func getData(_ key: String) -> Result<Data, UBKeychainError> {
        var query = self.query(for: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
            case errSecItemNotFound:
                return .failure(.notFound)
            case noErr:
                guard let item = item as? Data else {
                    return .failure(.keychainNotReturningData)
                }
                return .success(item)
            default:
                logger.error("SecItemCopyMatching returned status:\(status, privacy: .public) errorMessage: \(SecCopyErrorMessageString(status, nil) ?? "N/A" as CFString, privacy: .public)")
                return .failure(.cannotAccess(status))
        }
    }

    /// Set a object to the keychain
    /// - Parameters:
    ///   - object: the object to set
    ///   - key: the keyobject to use
    /// - Returns: a result which either is successful or contains the error
    @discardableResult
    public func set<T: Codable>(_ object: T, for key: UBKeychainKey<T>, accessibility: UBKeychainAccessibility) -> Result<Void, UBKeychainError> {
        let data: Data
        do {
            data = try encoder.encode(object)
        } catch {
            return .failure(.encodingError(error))
        }
        var query = self.query(for: key.key, accessibility: accessibility)
        query[kSecValueData as String] = data

        var status: OSStatus = SecItemCopyMatching(query as CFDictionary, nil)

        switch status {
            case errSecSuccess:
                // Item exists so we can update it
                let attributes = [kSecValueData: data]
                status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
                if status != errSecSuccess {
                    logger.error("SecItemUpdate returned status:\(status, privacy: .public) errorMessage: \(SecCopyErrorMessageString(status, nil) ?? "N/A" as CFString, privacy: .public)")
                    return .failure(.storingError(status))
                } else {
                    return .success(())
                }
            case errSecItemNotFound:
                // First time setting item
                status = SecItemAdd(query as CFDictionary, nil)

                if status != noErr {
                    logger.error("SecItemAdd returned status:\(status, privacy: .public) errorMessage: \(SecCopyErrorMessageString(status, nil) ?? "N/A" as CFString, privacy: .public)")
                    return .failure(.storingError(status))
                }
                return .success(())
            default:
                return .failure(.storingError(status))
        }
    }

    /// Deletes a object from the keychain
    /// - Parameter key: the key to delete
    /// - Returns: a result which either is successful or contains the error
    @discardableResult
    public func delete(for key: UBKeychainKey<some Any>) -> Result<Void, UBKeychainError> {
        let query = self.query(for: key.key)

        let status: OSStatus = SecItemDelete(query as CFDictionary)
        switch status {
            case noErr, errSecItemNotFound:
                return .success(())
            default:
                logger.error("SecItemDelete returned status:\(status, privacy: .public) errorMessage: \(SecCopyErrorMessageString(status, nil) ?? "N/A" as CFString, privacy: .public)")
                return .failure(.cannotDelete(status))
        }
    }

    /// helpermethod to construct the keychain query
    /// - Parameter key: key to use
    /// - Returns: the keychain query
    private func query(for key: String, accessibility: UBKeychainAccessibility? = nil) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
        ]
        if let accessibility {
            query[kSecAttrAccessible as String] = accessibility.rawValue
        }

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }

    /// Deletes all of the items in the keychain.
    /// iOS sometimes fails to delete all the items as the app is uninstalled, which results
    ///
    /// The app may choose to delete all the items to prevent undesirable behaviour.
    ///
    /// - Returns: Whether deleting the value succeded
    @discardableResult
    public func deleteAllItems() -> Result<Void, UBKeychainError> {
        let secClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]
        let status: [OSStatus] = secClasses.compactMap { secClass in
            let query: NSMutableDictionary = [kSecClass as String: secClass]

            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            let status = SecItemDelete(query as CFDictionary)

            if !(status == errSecSuccess || status == errSecItemNotFound) {
                logger.error("SecItemDelete returned status:\(status, privacy: .public) errorMessage: \(SecCopyErrorMessageString(status, nil) ?? "N/A" as CFString, privacy: .public)")
            }

            if status == errSecSuccess || status == errSecItemNotFound {
                return nil
            } else {
                return status
            }
        }
        if let firstErrror = status.min() {
            return .failure(.cannotDelete(firstErrror))
        } else {
            return .success(())
        }
    }
}
