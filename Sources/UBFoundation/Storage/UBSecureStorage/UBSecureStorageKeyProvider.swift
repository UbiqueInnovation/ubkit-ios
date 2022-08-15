//
//  UBSecureStorageKeyProvider.swift
//  
//
//  Created by Stefan Mitterrutzner on 10.06.22.
//

import Foundation

public protocol UBSecureStorageKeyProvider {

    func generateKey(with name: String) -> Result<SecKey, UBEnclaveError>

    func loadKey(with name: String) -> Result<SecKey, UBEnclaveError>

    func encrypt(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError>

    func decrypt(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError>

    func verify(data: Data, signature: Data, with key: SecKey) -> Result<Bool, UBEnclaveError>

    func sign(data: Data, with key: SecKey) -> Result<Data, UBEnclaveError>

}
