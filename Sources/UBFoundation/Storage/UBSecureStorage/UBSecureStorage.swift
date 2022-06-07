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

    private let filePath: URL

    private let enclave: UBEnclaveProtocol

    private let accessibility: UBKeychainAccessibility

    private let queue = DispatchQueue(label: "UBSecureStorageQueue")

    private let encoder: JSONEncoder

    private let decoder: JSONDecoder

    private let logger: UBLogger

    public static let sharedInstanceQueue = DispatchQueue(label: "UBSecureStorageSharedInstanceQueue")
    public static var sharedInstances: [UBKeychainAccessibility: UBSecureStorage] = [:]
    public static func shared(accessibility: UBKeychainAccessibility) -> UBSecureStorage {
        sharedInstanceQueue.sync {
            if let instance = sharedInstances[accessibility] {
                return instance
            }
            let fileName = (Bundle.main.bundleIdentifier ?? "app") + "." + accessibility.rawValue
            let instance = UBSecureStorage(fileName: fileName, accessibility: accessibility)
            sharedInstances[accessibility] = instance
            return instance
        }
    }

    struct UBSecureStorageWrapper: Codable {
        let encrypedData: Data
        let signature: Data
    }

    init(fileName: String = (Bundle.main.bundleIdentifier ?? "app"),
         enclave: UBEnclaveProtocol = UBEnclave(),
         accessibility: UBKeychainAccessibility = .whenUnlockedThisDeviceOnly,
         encoder: JSONEncoder = UBJSONEncoder(),
         decoder: JSONDecoder = UBJSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder

        self.enclave = enclave
        self.fileName = fileName
        self.accessibility = accessibility

        self.logger = UBLogging.frameworkLoggerFactory(category: "UBSecureStorage[\(fileName)]")

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = documentsPath[0]
        filePath = documentsDirectory.appendingPathComponent("\(fileName).ubSecStore")
    }

    private func loadOrGenerateKey() -> Result<SecKey, UBEnclaveError> {
        let loadKeyResult = enclave.loadKey(with: fileName)

        if case Result.success = loadKeyResult {
            return loadKeyResult
        }

        if case Result.failure(.keyLoadingError(errSecItemNotFound)) = loadKeyResult {
            self.logger.debug("generating Key")
            return enclave.generateKey(with: fileName, accessibility: accessibility)
        }

        return loadKeyResult
    }

    private func loadDict() -> Result<[String: Data], UBSecureStorageError>{
        dispatchPrecondition(condition: .onQueue(queue))

        guard FileManager.default.fileExists(atPath: filePath.path) else {
            logger.debug("file does not exist yet")
            return .success([:])
        }

        let data: Data
        do {
            data = try Data(contentsOf: filePath)
        } catch {
            logger.error("could not read file \(error.localizedDescription)")
            return .failure(.ioError(error))
        }

        let wrapper: UBSecureStorageWrapper
        do {
            wrapper = try decoder.decode(UBSecureStorageWrapper.self, from: data)
        } catch {
            logger.error("could not decode file \(error.localizedDescription)")
            return .failure(.decodingError(error))
        }

        let key: SecKey
        switch loadOrGenerateKey() {
        case let .success(key_):
            key = key_
        case let .failure(error):
            logger.error("could not loadOrGenerateKey \(error.errorCode)")
            return .failure(.enclaveError(error))
        }

        switch enclave.verify(data: wrapper.encrypedData, signature: wrapper.signature, with: key) {
        case let .success(success):
            if !success {
                logger.error("data verification failed")
                return .failure(.dataIntegrity)
            }
        case let .failure(error):
            logger.error("could not verify data on disk \(error.errorCode)")
            return .failure(.enclaveError(error))
        }

        let decryptedData: Data
        switch enclave.decrypt(data: wrapper.encrypedData, with: key) {
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

        let key: SecKey
        switch loadOrGenerateKey() {
        case let .success(key_):
            key = key_
        case let .failure(error):
            logger.error("could not loadOrGenerateKey \(error.errorCode)")
            return .failure(.enclaveError(error))
        }

        let encrypedData: Data
        switch enclave.encrypt(data: data, with: key) {
        case let .success(encrypedData_):
            encrypedData = encrypedData_
        case let .failure(error):
            logger.error("could not encrypt data \(error.errorCode)")
            return .failure(.enclaveError(error))
        }

        let signature: Data
        switch enclave.sign(data: encrypedData, with: key) {
        case let .success(signature_):
            signature = signature_
        case let .failure(error):
            logger.error("could not sign encrypted data \(error.errorCode)")
            return .failure(.enclaveError(error))
        }

        let wrapper = UBSecureStorageWrapper(encrypedData: encrypedData, signature: signature)

        let wrapperData: Data
        do {
            wrapperData = try encoder.encode(wrapper)
        } catch {
            logger.error("could not encode data \(error.localizedDescription)")
            return .failure(.encodingError(error))
        }

        do {
            try wrapperData.write(to: filePath)
        } catch {
            logger.error("could not write data \(error.localizedDescription)")
            return .failure(.ioError(error))
        }

        return .success(())
    }

    /// Get a object from the keychain
    /// - Parameter key: a key object with the type
    /// - Returns: a result which either contain the error or the object
    public func get<T>(for key: UBSecureStorageKey<T>) -> Result<T, UBSecureStorageError> where T: Decodable, T: Encodable {
        queue.sync {
            let dict: [String:Data]
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
    public func set<T>(_ object: T, for key: UBSecureStorageKey<T>) -> Result<Void, UBSecureStorageError> where T: Decodable, T: Encodable {
        queue.sync {
            var dict: [String:Data]
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
    public func delete<T>(for key: UBSecureStorageKey<T>) -> Result<Void, UBSecureStorageError> where T: Decodable, T: Encodable {
        queue.sync {
            var dict: [String:Data]
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
            return save(dict: [:])
        }
    }
    
}
