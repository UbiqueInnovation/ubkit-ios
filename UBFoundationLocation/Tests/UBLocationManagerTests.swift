//
//  UBLocationManagerTests.swift
//  UBFoundation iOS Tests
//
//  Created by Zeno Koller on 17.01.20.
//

import CoreLocation
@testable import UBFoundationLocation
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
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined, .authorizedWhenInUse]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationOnNewInstall_AlwaysGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined, .authorizedAlways]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationOnNewInstall_NotGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined, .denied]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationAfterRevoking_WhenInUseGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.denied, .authorizedWhenInUse]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationAfterRevoking_AlwaysGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.denied, .authorizedAlways]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testAuthorizationForLocationAfterRevoking_NotGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.denied, .denied]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    func testNoAuthorizationForLocationOnNewInstall_NotGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: false)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    func testNoAuthorizationForLocationAfterRevoking_NotGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: false)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    func testNoAuthorizationForLocation_WhenInUseGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.authorizedWhenInUse]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: false)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func testNoAuthorizationForLocation_AlwaysGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.authorizedAlways]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: false)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

    func makeSut() -> UBLocationManager {
        let sut = UBLocationManager(locationManager: mockLocationManager)
        mockLocationManager.delegate = sut
        return sut
    }

    func makeDelegate() -> UBLocationManagerDelegate {
        return MockLocationManagerDelegate()
    }
}
