//
//  LoggerGroupTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import os.log
import UBFoundation
import XCTest

class LoggerGroupTests: XCTestCase {
    func testLoggerGroup() {
        let l1 = Logger(try! OSLog(category: "T1", bundle: Bundle(for: LoggerGroupTests.self)))
        l1.setLogLevel(.verbose)
        let group = LoggerGroup(loggers: [
            l1,
            Logger(try! OSLog(category: "T2", bundle: Bundle(for: LoggerGroupTests.self))),
            Logger(try! OSLog(category: "T3", bundle: Bundle(for: LoggerGroupTests.self)))
        ])

        XCTAssertEqual(group.loggers.count, 3)
        group.add(logger: l1)
        XCTAssertEqual(group.loggers.count, 3)
        group.set(groupLogLevel: .none)
        for logger in group.loggers {
            XCTAssertEqual(logger.logLevel, Logger.LogLevel.none)
        }
        let l4 = Logger(try! OSLog(category: "T4", bundle: Bundle(for: LoggerGroupTests.self)))
        group.add(logger: l4)
        XCTAssertEqual(group.loggers.count, 4)
        group.remove(logger: l4)
        XCTAssertEqual(group.loggers.count, 3)
        XCTAssertFalse(group.loggers.contains(where: { $0 === l4 }))
    }
}
