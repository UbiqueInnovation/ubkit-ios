//
//  UBLocationManagerTests.swift
//  UBFoundation iOS Tests
//
//  Created by Zeno Koller on 17.01.20.
//

import CoreLocation
import XCTest

@testable import UBLocation

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

    @MainActor
    func testAuthorizationForLocationOnNewInstall_NotGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined, .denied]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    @MainActor
    func testAuthorizationForLocationAfterRevoking_NotGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.denied, .denied]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    @MainActor
    func testNoAuthorizationForLocationOnNewInstall_NotGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: false)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    @MainActor
    func testNoAuthorizationForLocationAfterRevoking_NotGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: false)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    @MainActor
    func makeSut() -> UBLocationManager {
        let sut = UBLocationManager(locationManager: mockLocationManager)
        mockLocationManager.delegate = sut
        return sut
    }

    @MainActor
    func makeDelegate() -> UBLocationManagerDelegate {
        MockLocationManagerDelegate()
    }
}
