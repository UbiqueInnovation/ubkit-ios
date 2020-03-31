//
//  UBLocationManagerTests.swift
//  UBFoundation iOS Tests
//
//  Created by Zeno Koller on 17.01.20.
//

import CoreLocation
@testable import UBFoundation
import XCTest

class UBLocationManagerTests: XCTestCase {
    var mockLocationManager: MockLocationManager!

    override func setUp() {
        super.setUp()
        mockLocationManager = MockLocationManager()
    }

    override func tearDown() {
        super.tearDown()
        mockLocationManager = nil
    }

    func testAuthorizationForLocationOnNewInstall_WhenInUseGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.notDetermined, .authorizedWhenInUse]

        sut.startLocationMonitoring(canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationOnNewInstall_AlwaysGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.notDetermined, .authorizedAlways]

        sut.startLocationMonitoring(canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationOnNewInstall_NotGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.notDetermined, .denied]

        sut.startLocationMonitoring(canAskForPermission: true)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationAfterRevoking_WhenInUseGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.denied, .authorizedWhenInUse]

        sut.startLocationMonitoring(canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationAfterRevoking_AlwaysGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.denied, .authorizedAlways]

        sut.startLocationMonitoring(canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationAfterRevoking_NotGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.denied, .denied]

        sut.startLocationMonitoring(canAskForPermission: true)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    func testNoAuthorizationForLocationOnNewInstall_NotGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.notDetermined]

        sut.startLocationMonitoring(canAskForPermission: false)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    func testNoAuthorizationForLocationAfterRevoking_NotGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.notDetermined]

        sut.startLocationMonitoring(canAskForPermission: false)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    func testNoAuthorizationForLocation_WhenInUseGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.authorizedWhenInUse]

        sut.startLocationMonitoring(canAskForPermission: false)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testNoAuthorizationForLocation_AlwaysGranted() {
        let sut = makeSut(forUsage: .location)
        mockLocationManager.authorizationStatuses = [.authorizedAlways]

        sut.startLocationMonitoring(canAskForPermission: false)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func makeSut(forUsage usage: UBLocationManager.LocationMonitoringUsage) -> UBLocationManager {
        let sut = UBLocationManager(usage: usage, locationManager: mockLocationManager)
        mockLocationManager.delegate = sut
        return sut
    }
}