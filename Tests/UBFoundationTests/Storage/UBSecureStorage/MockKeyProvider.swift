//
//  MockKeyProvider.swift
//  
//
//  Created by Stefan Mitterrutzner on 15.08.22.
//

@testable import UBFoundation
import XCTest

class MockKeyProvider: UBSecureStorageKeyProvider {

    private let encryptAlg = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    private let signAlg = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA512


    var secureKeyStorage: [String: SecKey] = [:]

    func generateKey(with name: String) -> Result<SecKey, UBFoundation.UBEnclaveError> {
        let attributes: [String: Any] = [
            kSecAttrType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256
        ]

        var error: Unmanaged<CFError>?
        let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error)!

        secureKeyStorage[name] = key

        return .success(key)
    }

    func loadKey(with name: String) -> Result<SecKey, UBFoundation.UBEnclaveError> {
        if let key = secureKeyStorage[name] {
            return .success(key)
        } else {
            return .failure(.keyLoadingError(errSecItemNotFound))
        }
    }

    public func encrypt(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError> {
        guard let publicKey = SecKeyCopyPublicKey(key) else {
            return .failure(UBEnclaveError.pubkeyIrretrievable)
        }
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, encryptAlg) else {
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
            return .failure(UBEnclaveError.secError(error))
        }
        if let cipherData = cipherData {
            return .success(cipherData)
        }
        fatalError()
    }

    public func decrypt(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError> {
        guard SecKeyIsAlgorithmSupported(key, .decrypt, encryptAlg) else {
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
            return .failure(UBEnclaveError.secError(error))
        }
        if let clearData = clearData {
            return .success(clearData)
        }
        fatalError()
    }

    public func verify(data: Data, signature: Data, with key: SecKey) -> Result<Bool, UBEnclaveError> {
        guard let publicKey = SecKeyCopyPublicKey(key) else {
            return .failure(UBEnclaveError.pubkeyIrretrievable)
        }
        guard SecKeyIsAlgorithmSupported(publicKey, .verify, signAlg) else {
            return .failure(UBEnclaveError.algNotSupported)
        }
        var error: Unmanaged<CFError>?
        let isValid = SecKeyVerifySignature(
            publicKey,
            signAlg,
            data as CFData,
            signature as CFData,
            &error
        )
        if let error = error?.takeRetainedValue() {
            return .failure(UBEnclaveError.secError(error))
        }
        return .success(isValid)
    }

    public func sign(
        data: Data,
        with key: SecKey
    ) -> Result<Data, UBEnclaveError> {
        guard SecKeyIsAlgorithmSupported(key, .sign, signAlg) else {
            return .failure(UBEnclaveError.algNotSupported)
        }
        var error: Unmanaged<CFError>?
        let signature = SecKeyCreateSignature(
            key,
            signAlg,
            data as CFData,
            &error
        ) as Data?
        if let error = error?.takeRetainedValue() {
            return .failure(UBEnclaveError.secError(error))
        }
        if let signature = signature {
            return .success(signature)
        }
        fatalError()
    }
}
