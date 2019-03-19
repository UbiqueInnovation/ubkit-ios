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
        UBFoundation.Logging.setGlobalLogLevel(.none)
        UBFoundation.Logging.setGlobalLogLevel(.verbose)
        UBFoundation.Logging.setGlobalLogLevel(.default)
    }
}
