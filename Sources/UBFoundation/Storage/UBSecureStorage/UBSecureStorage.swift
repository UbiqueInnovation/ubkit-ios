//
//  UBSecureStorage.swift
//
//
//  Created by Stefan Mitterrutzner on 03.06.22.
//

import Foundation
import UIKit

@available(iOS 11.0, *)
public class UBSecureStorage {
    private let fileName: String

    private var filePath: URL

    private let keyProvider: UBSecureStorageKeyProviderProtocol

    private let accessibility: UBKeychainAccessibility

    private let queue = DispatchQueue(label: "UBSecureStorageQueue")

    private let encoder: JSONEncoder

    private let decoder: JSONDecoder

    private let logger: UBLogger

    private static let sharedInstanceQueue = DispatchQueue(label: "UBSecureStorageSharedInstanceQueue")
    private static var sharedInstances: [UBKeychainAccessibility: UBSecureStorage] = [:]
    public static func shared(accessibility: UBKeychainAccessibility) -> UBSecureStorage {
        sharedInstanceQueue.sync {
            if let instance = sharedInstances[accessibility] {
                return instance
            }
            let fileName = (Bundle.main.bundleIdentifier ?? "app") + "." + accessibility.secureStorageFileName
            let instance = UBSecureStorage(fileName: fileName, accessibility: accessibility)
            sharedInstances[accessibility] = instance
            return instance
        }
    }

    init(fileName: String = (Bundle.main.bundleIdentifier ?? "app"),
         keyProvider: UBSecureStorageKeyProviderProtocol? = nil,
         accessibility: UBKeychainAccessibility = .whenUnlockedThisDeviceOnly,
         encoder: JSONEncoder = UBJSONEncoder(),
         decoder: JSONDecoder = UBJSONDecoder(),
         excludeFileFromBackup: Bool = true,
         fileProtection: FileProtectionType? = .complete) {
        self.keyProvider = keyProvider ?? UBSecureStorageKeyProvider(accessibility: accessibility)
        self.encoder = encoder
        self.decoder = decoder

        self.fileName = fileName
        self.accessibility = accessibility

        self.logger = UBLogging.frameworkLoggerFactory(category: "UBSecureStorage[\(fileName)]")

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = documentsPath[0]
        filePath = documentsDirectory.appendingPathComponent("\(fileName).ubSecStore")

        if excludeFileFromBackup {
            do {
                var res = URLResourceValues()
                res.isExcludedFromBackup = true
                try filePath.setResourceValues(res)
            } catch { }
        }

        if let fileProtection = fileProtection {
            try? FileManager.default.setAttributes([
                .protectionKey: fileProtection
            ], ofItemAtPath: filePath.path)
        }
    }

    private func loadKey() -> Result<SecKey, UBSecureStorageError> {
        switch keyProvider.loadKey(with: fileName) {
            case let .success(key):
                return .success(key)
            case let .failure(error):
                return .failure(.encodingError(error))
        }
    }

    private func generateKey() -> Result<SecKey, UBSecureStorageError> {
        switch keyProvider.generateKey(with: fileName) {
            case let .success(key):
                return .success(key)
            case let .failure(error):
                return .failure(.encodingError(error))
        }
    }


    private func loadDict() -> Result<[String: Data], UBSecureStorageError> {
        dispatchPrecondition(condition: .onQueue(queue))

        guard FileManager.default.fileExists(atPath: filePath.path) else {
            logger.debug("file does not exist yet")
            return .success([:])
        }

        let encrypedData: Data
        do {
            encrypedData = try Data(contentsOf: filePath)
        } catch {
            logger.error("could not read file \(error.localizedDescription)")
            return .failure(.ioError(error))
        }


        let key: SecKey
        switch loadKey() {
            case let .success(key_):
                key = key_
            case let .failure(error):
                logger.error("could not loadKey \(error.errorCode)")
                return .failure(.enclaveError(error))
        }

        let decryptedData: Data
        switch keyProvider.decrypt(data: encrypedData, with: key) {
            case let .success(data):
                decryptedData = data
            case let .failure(error):
                logger.error("could not decrypt data on disk \(error.errorCode)")
                return .failure(.enclaveError(error))
        }

        do {
            return .success(try decoder.decode([String: Data].self, from: decryptedData))
        } catch {
            logger.error("could not decoded encrypted data \(error.localizedDescription)")
            return .failure(.decodingError(error))
        }
    }

    private func save(dict: [String: Data]) -> Result<Void, UBSecureStorageError> {
        dispatchPrecondition(condition: .onQueue(queue))

        let data: Data
        do {
            data = try encoder.encode(dict)
        } catch {
            logger.error("could not encode data \(error.localizedDescription)")
            return .failure(.encodingError(error))
        }


        var key: SecKey?
        if !FileManager.default.fileExists(atPath: filePath.path) {
            logger.debug("file does not exist yet therefore we generate a key")

            switch generateKey() {
                case let .success(key_):
                    key = key_
                case let .failure(error):
                    logger.error("could not generateKey \(error.errorCode)")
                    return .failure(.enclaveError(error))

            }
        }

        if key == nil {
            switch loadKey() {
                case let .success(key_):
                    key = key_
                case let .failure(error):
                    logger.error("could not loadKey \(error.errorCode)")
                    return .failure(.enclaveError(error))
            }
        }

        let encrypedData: Data
        switch keyProvider.encrypt(data: data, with: key!) {
            case let .success(encrypedData_):
                encrypedData = encrypedData_
            case let .failure(error):
                logger.error("could not encrypt data \(error.errorCode)")
                return .failure(.enclaveError(error))
        }

        do {
            try encrypedData.write(to: filePath)
        } catch {
            logger.error("could not write data \(error.localizedDescription)")
            return .failure(.ioError(error))
        }

        return .success(())
    }

    /// Get a object from the keychain
    /// - Parameter key: a key object with the type
    /// - Returns: a result which either contain the error or the object
    public func get<T>(for key: UBSecureStorageValueKey<T>) -> Result<T, UBSecureStorageError> where T: Decodable, T: Encodable {
        queue.sync {
            let dict: [String: Data]
            switch loadDict() {
                case let .success(dict_):
                    dict = dict_
                case let .failure(error):
                    return .failure(error)
            }
            guard let data = dict[key.key] else {
                return .failure(.notFound)
            }

            do {
                return .success(try decoder.decode(T.self, from: data))
            } catch {
                return .failure(.decodingError(error))
            }
        }
    }

    @discardableResult
    public func set<T>(_ object: T, for key: UBSecureStorageValueKey<T>) -> Result<Void, UBSecureStorageError> where T: Decodable, T: Encodable {
        queue.sync {
            var dict: [String: Data]
            switch loadDict() {
                case let .success(dict_):
                    dict = dict_
                case let .failure(error):
                    return .failure(error)
            }

            do {
                dict[key.key] = try encoder.encode(object)
            } catch {
                return .failure(.encodingError(error))
            }

            return save(dict: dict)
        }
    }

    @discardableResult
    public func delete<T>(for key: UBSecureStorageValueKey<T>) -> Result<Void, UBSecureStorageError> where T: Decodable, T: Encodable {
        queue.sync {
            var dict: [String: Data]
            switch loadDict() {
                case let .success(dict_):
                    dict = dict_
                case let .failure(error):
                    return .failure(error)
            }

            dict.removeValue(forKey: key.key)

            return save(dict: dict)
        }
    }

    @discardableResult
    public func deleteAllItems() -> Result<Void, UBSecureStorageError> {
        queue.sync {
            try? FileManager.default.removeItem(atPath: filePath.path)
            return .success(())
        }
    }
}
