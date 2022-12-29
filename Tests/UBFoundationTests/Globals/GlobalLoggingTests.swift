//
//  GlobalLoggingTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import UBFoundation
import XCTest

class GlobalLoggingTests: XCTestCase {
    func testSetGlobalLogLevel() {
        UBFoundation.UBLogging.setGlobalLogLevel(.none)
        UBFoundation.UBLogging.setGlobalLogLevel(.verbose)
        UBFoundation.UBLogging.setGlobalLogLevel(.default)
    }
}
#endif
