//
//  CronJobTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 27.03.19.
//

import UBFoundation
import XCTest

class CronJobTests: XCTestCase {
    func testCronInvocationAfterTimeInterval() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.3
        let job = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            ex.fulfill()
        }
        XCTAssertEqual(job.name, "Test Cron")
        wait(for: [ex], timeout: testDuration * 1.1)
    }

    func testCronInvocationAtDate() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.3
        let job = UBCronJob(fireAt: Date(timeIntervalSinceNow: testDuration), name: "Test Cron") {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            ex.fulfill()
        }
        XCTAssertEqual(job.name, "Test Cron")
        wait(for: [ex], timeout: testDuration * 1.1)
    }

    func testCronInvocationOnMainThread() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.3
        let job = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            ex.fulfill()
        }
        job.callbackQueue = .main
        wait(for: [ex], timeout: testDuration * 1.1)
    }

    func testCronChangeExecutionBlock() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.3
        let job = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
            XCTFail("Should not have executed this block")
        }
        job.executionBlock = {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            ex.fulfill()
        }
        wait(for: [ex], timeout: testDuration * 4)
    }

    func testCronIntervalChange() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.2
        let newTestDuration: TimeInterval = 0.35
        let job = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), newTestDuration * 0.9)
            ex.fulfill()
        }
        job.setFireAfter(newTestDuration)

        wait(for: [ex], timeout: newTestDuration * 1.1)
    }

    func testCronDateChange() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.2
        let newTestDuration: TimeInterval = 0.35
        let job = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), newTestDuration * 0.9)
            ex.fulfill()
        }
        job.setFireAt(Date(timeIntervalSinceNow: newTestDuration))

        wait(for: [ex], timeout: newTestDuration * 1.1)
    }

    func testCronDateInPast() {
        let ex = expectation(description: "Cron Test")
        let job = UBCronJob(fireAt: Date(timeIntervalSinceNow: -1), name: "Test Cron") {
            ex.fulfill()
        }
        XCTAssertEqual(job.name, "Test Cron")
        wait(for: [ex], timeout: 0.05)
    }

    func testPause() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.2
        let job = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
            XCTFail()
        }
        job.pause()
        let t = Timer(timeInterval: testDuration * 1.5, repeats: false) { _ in
            ex.fulfill()
        }
        RunLoop.main.add(t, forMode: .common)

        wait(for: [ex], timeout: testDuration * 2)
    }

    func testPauseAndResumeBeforeDeadline() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.4
        let date = Date()
        let job = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            ex.fulfill()
        }
        job.pause()
        let t = Timer(timeInterval: 0.2, repeats: false) { _ in
            job.resume()
        }
        RunLoop.main.add(t, forMode: .common)

        wait(for: [ex], timeout: testDuration * 1.1)
    }

    func testPauseAndResumeAfterDeadline() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.2
        let pauseTime: TimeInterval = 0.4
        let date = Date()
        let job = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), pauseTime * 0.9)
            ex.fulfill()
        }
        job.pause()
        let t = Timer(timeInterval: pauseTime, repeats: false) { _ in
            job.resume()
        }
        RunLoop.main.add(t, forMode: .common)

        wait(for: [ex], timeout: 30)
    }

    func testDeallocation() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.2
        weak var job: UBCronJob?

        autoreleasepool {
            let j = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
                XCTFail()
            }
            job = j
        }
        XCTAssertNil(job)
        let t = Timer(timeInterval: testDuration * 1.5, repeats: false) { _ in
            ex.fulfill()
        }
        RunLoop.main.add(t, forMode: .common)
        wait(for: [ex], timeout: testDuration * 2)
    }

    func testPausedDeallocation() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.2
        weak var job: UBCronJob?

        autoreleasepool {
            let j = UBCronJob(fireAfter: testDuration, name: "Test Cron") {
                XCTFail()
            }
            j.pause()
            job = j
        }
        XCTAssertNil(job)
        let t = Timer(timeInterval: testDuration * 1.5, repeats: false) { _ in
            ex.fulfill()
        }
        RunLoop.main.add(t, forMode: .common)
        wait(for: [ex], timeout: testDuration * 2)
    }
}
