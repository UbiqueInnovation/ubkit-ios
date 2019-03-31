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
        let job = CronJob(fireAfter: testDuration) {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            ex.fulfill()
        }
        job.name = "Test Cron"
        waitForExpectations(timeout: testDuration * 1.1, handler: nil)
    }

    func testCronInvocationAtDate() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.3
        let job = CronJob(fireAt: Date(timeIntervalSinceNow: testDuration)) {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            ex.fulfill()
        }
        job.name = "Test Cron"
        waitForExpectations(timeout: testDuration * 1.1, handler: nil)
    }

    func testCronInvocationOnMainThread() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.3
        let job = CronJob(fireAfter: testDuration) {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            ex.fulfill()
        }
        job.callbackQueue = .main
        job.name = "Test Cron"
        waitForExpectations(timeout: testDuration * 1.1, handler: nil)
    }

    func testCronChangeExecutionBlock() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.3
        let job = CronJob(fireAfter: testDuration) {
            XCTFail("Should not have executed this block")
        }
        job.name = "Test Cron"
        job.executionBlock = {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            ex.fulfill()
        }
        waitForExpectations(timeout: testDuration * 2, handler: nil)
    }

    func testCronIntervalChange() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.2
        let newTestDuration: TimeInterval = 0.35
        let job = CronJob(fireAfter: testDuration) {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), newTestDuration * 0.9)
            ex.fulfill()
        }
        job.name = "Test Cron"
        job.setFireAfter(newTestDuration)

        waitForExpectations(timeout: newTestDuration * 1.1, handler: nil)
    }

    func testCronDateChange() {
        let ex = expectation(description: "Cron test")
        let date = Date()
        let testDuration: TimeInterval = 0.2
        let newTestDuration: TimeInterval = 0.35
        let job = CronJob(fireAfter: testDuration) {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), newTestDuration * 0.9)
            ex.fulfill()
        }
        job.name = "Test Cron"
        job.setFireAt(Date(timeIntervalSinceNow: newTestDuration))

        waitForExpectations(timeout: newTestDuration * 1.1, handler: nil)
    }

    func testCronDateInPast() {
        let ex = expectation(description: "Cron Test")
        let job = CronJob(fireAt: Date(timeIntervalSinceNow: -1)) {
            ex.fulfill()
        }
        job.name = "Test Cron"
        waitForExpectations(timeout: 0.05, handler: nil)
    }

    func testPause() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.2
        let job = CronJob(fireAfter: testDuration) {
            XCTFail()
        }
        job.name = "Test Cron"
        job.pause()
        let t = Timer(timeInterval: testDuration * 1.5, repeats: false) { _ in
            ex.fulfill()
        }
        RunLoop.main.add(t, forMode: .common)

        waitForExpectations(timeout: testDuration * 2, handler: nil)
    }

    func testPauseAndResumeBeforeDeadline() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.4
        let date = Date()
        let job = CronJob(fireAfter: testDuration) {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), testDuration * 0.9)
            ex.fulfill()
        }
        job.name = "Test Cron"
        job.pause()
        let t = Timer(timeInterval: 0.2, repeats: false) { _ in
            job.resume()
        }
        RunLoop.main.add(t, forMode: .common)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testPauseAndResumeAfterDeadline() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.2
        let pauseTime: TimeInterval = 0.4
        let date = Date()
        let job = CronJob(fireAfter: testDuration) {
            XCTAssertGreaterThan(abs(date.timeIntervalSinceNow), pauseTime * 0.9)
            ex.fulfill()
        }
        job.name = "Test Cron"
        job.pause()
        let t = Timer(timeInterval: pauseTime, repeats: false) { _ in
            job.resume()
        }
        RunLoop.main.add(t, forMode: .common)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDeallocation() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.2
        weak var job: CronJob?

        autoreleasepool {
            let j = CronJob(fireAfter: testDuration) {
                XCTFail()
            }
            j.name = "Cron Test"
            job = j
        }
        XCTAssertNil(job)
        let t = Timer(timeInterval: testDuration * 1.5, repeats: false) { _ in
            ex.fulfill()
        }
        RunLoop.main.add(t, forMode: .common)
        waitForExpectations(timeout: testDuration * 2, handler: nil)
    }

    func testPausedDeallocation() {
        let ex = expectation(description: "Cron test")
        let testDuration: TimeInterval = 0.2
        weak var job: CronJob?

        autoreleasepool {
            let j = CronJob(fireAfter: testDuration) {
                XCTFail()
            }
            j.name = "Cron Test"
            j.pause()
            job = j
        }
        XCTAssertNil(job)
        let t = Timer(timeInterval: testDuration * 1.5, repeats: false) { _ in
            ex.fulfill()
        }
        RunLoop.main.add(t, forMode: .common)
        waitForExpectations(timeout: testDuration * 2, handler: nil)
    }
}
