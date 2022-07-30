//
//  UBEnclaveProtocol.swift
//
//
//  Created by Stefan Mitterrutzner on 07.06.22.
//

import Foundation

protocol UBEnclaveProtocol {
    func generateKey(with name: String, accessibility: UBKeychainAccessibility) -> Result<SecKey, UBEnclaveError>

    func loadKey(with name: String) -> Result<SecKey, UBEnclaveError>

    func encrypt(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError>

    func decrypt(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError>

    func verify(data: Data, signature: Data, with key: SecKey) -> Result<Bool, UBEnclaveError>

    func sign(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError>
}
