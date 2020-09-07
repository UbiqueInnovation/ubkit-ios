//
//  GlobalLoggingTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import UBFoundation
import XCTest

class GlobalLoggingTests: XCTestCase {
    func testSetGlobalLogLevel() {
        UBFoundation.UBLogging.setGlobalLogLevel(.none)
        UBFoundation.UBLogging.setGlobalLogLevel(.verbose)
        UBFoundation.UBLogging.setGlobalLogLevel(.default)
    }
}
