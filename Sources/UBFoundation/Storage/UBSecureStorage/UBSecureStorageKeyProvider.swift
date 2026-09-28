//
//  UBSecureStorage.swift
//
//
//  Created by Stefan Mitterrutzner on 03.06.22.
//

import Foundation

@available(iOS 11.0, *)
public class UBSecureStorageKeyProvider: UBSecureStorageKeyProviderProtocol {
    private let encryptAlg = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    private let signAlg = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA512
    private let accessibility: UBKeychainAccessibility

    let logger: UBLogger = UBLogging.frameworkLoggerFactory(category: "UBSecureStorageKeyProvider")

    private func tag(for name: String) -> Data {
        "\(Bundle.main.bundleIdentifier ?? "app").\(name)".data(using: .utf8)!
    }

    init(accessibility: UBKeychainAccessibility) {
        self.accessibility = accessibility
    }

    public func generateKey(with name: String) -> Result<SecKey, UBEnclaveError> {
        let name = name
        let tag = tag(for: name)
        var error: Unmanaged<CFError>?
        guard
            let access =
            SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                accessibility.cfString,
                [],
                &error
            )
        else {
            if let error = error?.takeRetainedValue() {
                logger.error(error.localizedDescription)
                return .failure(UBEnclaveError.secError(error))
            }
            fatalError("SecAccessControlCreateWithFlags neither returned an error nor a access")
        }
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access,
            ],
        ]
        guard
            let privateKey = SecKeyCreateRandomKey(
                attributes as CFDictionary,
                &error
            )
        else {
            if let error = error?.takeRetainedValue() {
                logger.error(error.localizedDescription)
                return .failure(UBEnclaveError.secError(error))
            }
            fatalError("SecKeyCreateRandomKey neither returned an error nor a key")
        }
        return .success(privateKey)
    }

    public func loadKey(with name: String) -> Result<SecKey, UBEnclaveError> {
        let tag = tag(for: name)
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrApplicationTag as String: tag,
            kSecReturnRef as String: true,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard
            status == errSecSuccess,
            case let result as SecKey = item
        else {
            return .failure(UBEnclaveError.keyLoadingError(status))
        }
        return .success(result)
    }

    public func encrypt(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError> {
        guard let publicKey = SecKeyCopyPublicKey(key) else {
            logger.error("encrypt.err.pub-key-irretrievable")
            return .failure(UBEnclaveError.pubkeyIrretrievable)
        }
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, encryptAlg) else {
            logger.error("encrypt.err.alg-not-supported")
            return .failure(UBEnclaveError.algNotSupported)
        }
        var error: Unmanaged<CFError>?
        let cipherData = SecKeyCreateEncryptedData(
            publicKey,
            encryptAlg,
            data as CFData,
            &error
        ) as Data?
        if let error = error?.takeRetainedValue() {
            logger.error("encrypt.\(error.localizedDescription)")
            return .failure(UBEnclaveError.secError(error))
        }
        if let cipherData = cipherData {
            return .success(cipherData)
        }
        fatalError()
    }

    public func decrypt(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError> {
        guard SecKeyIsAlgorithmSupported(key, .decrypt, encryptAlg) else {
            logger.error("decrypt.err.alg-not-supported")
            return .failure(UBEnclaveError.algNotSupported)
        }
        var error: Unmanaged<CFError>?
        let clearData = SecKeyCreateDecryptedData(
            key,
            encryptAlg,
            data as CFData,
            &error
        ) as Data?
        if let error = error?.takeRetainedValue() {
            logger.error("decrypt.\(error.localizedDescription)")
            return .failure(UBEnclaveError.secError(error))
        }
        if let clearData = clearData {
            return .success(clearData)
        }
        fatalError()
    }
}
