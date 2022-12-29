//
//  UBCodedError.swift
//
//
//  Created by Zeno Koller on 06.01.21.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

public protocol UBCodedError {
    var errorCode: String { get }
}
#endif
