//
//  LoggerTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import os.log
import UBFoundation
import XCTest

class LoggerTests: XCTestCase {
    func testLogFromMain() {
        let logger = try! UBLogger(category: "Tests", bundle: Bundle(for: LoggerTests.self))
        for level in [UBLogger.LogLevel.default, UBLogger.LogLevel.verbose, UBLogger.LogLevel.none] {
            logger.setLogLevel(level)
            for access in [UBLogger.AccessLevel.public, UBLogger.AccessLevel.private] {
                logger.debug("Test Log Debug", accessLevel: access)
                logger.info("Test Log Info", accessLevel: access)
                logger.error("Test Log Error", accessLevel: access)
            }
        }
    }

    func testLogFromThread() {
        let operationQueue = OperationQueue()
        let logger = try! UBLogger(category: "Tests", bundle: Bundle(for: LoggerTests.self))
        let expectation = XCTestExpectation(description: "Wait for log")
        operationQueue.addOperation {
            logger.info("Test Info from thread")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
    }

    func testMultiThreadingLog() {
        let logger = try! UBLogger(category: "Tests", bundle: Bundle(for: LoggerTests.self))
        let expectation1 = XCTestExpectation(description: "Wait for log 1")
        let expectation2 = XCTestExpectation(description: "Wait for log 2")
        let operationQueue1 = OperationQueue()
        let operationQueue2 = OperationQueue()
        operationQueue1.addOperation {
            for _ in 1 ... 200 {
                logger.info("Test Info from thread")
            }
            expectation1.fulfill()
        }
        operationQueue2.addOperation {
            for _ in 1 ... 200 {
                logger.info("Test Info from thread")
            }
            expectation2.fulfill()
        }
    }

    func testNoBundleIdentifier() {
        let testBundlePath = Bundle.module.path(forResource: "TestResources/LoggingTestBundle", ofType: nil)!
        let testBundle = Bundle(path: testBundlePath)!
        XCTAssertThrowsError(try UBLogger(category: "Failing", bundle: testBundle), "Should have failed because of missing bundle identifier") { error in
            XCTAssertEqual(error as? UBLoggingError, UBLoggingError.bundelIdentifierNotFound)
        }
    }

    func testPerformanceACLDefault() {
        let logger = try! UBLogger(category: "Tests", bundle: Bundle(for: LoggerTests.self))
        logger.setLogLevel(.default)
        measure {
            for _ in 1 ... 1000 {
                logger.debug("Test Log Debug", accessLevel: .private)
            }
        }
    }

    func testPerformanceACLNone() {
        let logger = try! UBLogger(category: "Tests", bundle: Bundle(for: LoggerTests.self))
        logger.setLogLevel(.none)
        measure {
            for _ in 1 ... 1000 {
                logger.debug("Test Log Debug", accessLevel: .private)
            }
        }
    }

    func testPerformanceACLVerbose() {
        let logger = try! UBLogger(category: "Tests", bundle: Bundle(for: LoggerTests.self))
        logger.setLogLevel(.verbose)
        measure {
            for _ in 1 ... 1000 {
                logger.debug("Test Log Debug", accessLevel: .private)
            }
        }
    }
}
