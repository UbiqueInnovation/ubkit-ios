//
//  UBCodedError.swift
//  
//
//  Created by Zeno Koller on 06.01.21.
//

import Foundation

public protocol UBCodedError: Error {
    var errorCode: String { get }
}
