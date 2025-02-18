//
//  UBLocationManagerTests.swift
//  UBFoundation iOS Tests
//
//  Created by Zeno Koller on 17.01.20.
//

import CoreLocation
@testable import UBLocation
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

    @MainActor
    func testAuthorizationForLocationOnNewInstall_WhenInUseGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined, .authorizedWhenInUse]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

#if !os(visionOS)
    @MainActor
    func testAuthorizationForLocationOnNewInstall_AlwaysGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined, .authorizedAlways]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }
#endif

    @MainActor
    func testAuthorizationForLocationOnNewInstall_NotGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.notDetermined, .denied]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(!mockLocationManager.isUpdatingLocation)
    }

    @MainActor
    func testAuthorizationForLocationAfterRevoking_WhenInUseGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.denied, .authorizedWhenInUse]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

#if !os(visionOS)
    @MainActor
    func testAuthorizationForLocationAfterRevoking_AlwaysGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.denied, .authorizedAlways]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: true)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }
#endif

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
    func testNoAuthorizationForLocation_WhenInUseGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.authorizedWhenInUse]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: false)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }

#if !os(visionOS)
    @MainActor
    func testNoAuthorizationForLocation_AlwaysGranted() {
        let sut = makeSut()
        mockLocationManager.authorizationStatuses = [.authorizedAlways]

        sut.startLocationMonitoring(for: .location(background: false), delegate: makeDelegate(), canAskForPermission: false)

        XCTAssert(mockLocationManager.isUpdatingLocation)
    }
#endif

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
