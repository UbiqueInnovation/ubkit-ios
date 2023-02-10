//
//  UBKeychainProtocol.swift
//
//
//  Created by Stefan Mitterrutzner on 08.12.21.
//

import Foundation

/// Keychain protocol to make unit testing possible
public protocol UBKeychainProtocol {
    /// A Identifer which can be used to compare multiple Keychain Instances
    /// This is useful for creating a mock keychain
    var identifier: String { get }

    /// Get a object from the keychain
    /// - Parameter key: a key object with the type
    /// - Returns: a result which either contain the error or the object
    func get<T>(for key: UBKeychainKey<T>) -> Result<T, UBKeychainError> where T: Decodable, T: Encodable

    /// Retrieves data item from the Keychain
    ///
    /// - Parameters:
    ///     - key: The key referring to the value
    /// - Returns: The value, if it exists
    func getData(_ key: String) -> Result<Data, UBKeychainError>

    /// Set a object to the keychain
    /// - Parameters:
    ///   - object: the object to set
    ///   - key: the keyobject to use
    ///   - accessibility: Determines where the value can be accessed
    /// - Returns: a result which either is successful or contains the error
    @discardableResult
    func set<T>(_ object: T, for key: UBKeychainKey<T>, accessibility: UBKeychainAccessibility) -> Result<Void, UBKeychainError> where T: Decodable, T: Encodable

    /// Deletes a object from the keychain
    /// - Parameter key: the key to delete
    /// - Returns: a result which either is successful or contains the error
    @discardableResult
    func delete<T>(for key: UBKeychainKey<T>) -> Result<Void, UBKeychainError> where T: Decodable, T: Encodable

    /// Deletes all objects from keychain
    /// - Returns: a result which either is successful or contains the error
    @discardableResult
    func deleteAllItems() -> Result<Void, UBKeychainError>
}
