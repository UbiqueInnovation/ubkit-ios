//
//  UBObserverTests.swift
//  
//
//  Created by Joseph El Mallah on 10.02.23.
//

import XCTest
import UBFoundation

final class UBObserverTests: XCTestCase {

    private var reference: Any?

    func testManagedNotificationCenterObservationRemoval() {
        let notificationCenter = NotificationCenter()
        let notificationName: Notification.Name = Notification.Name(rawValue: "A")
        let expectation = expectation(description: "Notification Callback")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
        reference = notificationCenter.addUBObserver(forName: notificationName) { _ in
            expectation.fulfill()
        }
        notificationCenter.post(name: notificationName, object: nil)
        reference = nil
        notificationCenter.post(name: notificationName, object: nil)
        wait(for: [expectation], timeout: 1)
    }

}
