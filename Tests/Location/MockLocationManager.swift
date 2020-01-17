//
//  MockLocationManager.swift
//  UBFoundation iOS Tests
//
//  Created by Zeno Koller on 17.01.20.
//

import Foundation
import UBFoundation
import CoreLocation


class MockLocationManager: UBLocationManagerProtocol {

    /// The sequence of authorizationStatues that is traversed when requesting Authorization
    var authorizationStatuses: [CLAuthorizationStatus] = []

    var _authorizationStatus: CLAuthorizationStatus {
        guard let currentAuthorizationStatus = authorizationStatuses.first else {
            fatalError()
        }
        return currentAuthorizationStatus
    }

    var isUpdatingLocation: Bool = false
    var isMonitoringSignificantLocationChanges: Bool = false
    var isMonitoringVisits: Bool = false
    var isUpdatingHeading: Bool = false

    // MARK: - UBLocationManagerProtocol properties

    var location: CLLocation? {
        CLLocation(latitude: 47.376794, longitude: 8.543733)
    }

    var delegate: CLLocationManagerDelegate?

    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone

    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest

    var headingFilter: CLLocationDegrees = kCLHeadingFilterNone

    // MARK: - Starting / stopping location services

    func startUpdatingLocation() {
        isUpdatingLocation = true
    }

    func stopUpdatingLocation() {
        isUpdatingLocation = false
    }

    func startMonitoringSignificantLocationChanges() {
        isMonitoringSignificantLocationChanges = true
    }

    func stopMonitoringSignificantLocationChanges() {
        isMonitoringSignificantLocationChanges = false
    }

    func startMonitoringVisits() {
        isMonitoringVisits = true
    }

    func stopMonitoringVisits() {
        isMonitoringVisits = false
    }

    func startUpdatingHeading() {
        isUpdatingHeading = true
    }

    func stopUpdatingHeading() {
        isUpdatingHeading = false
    }

    // MARK: - Authorization

    func requestWhenInUseAuthorization() {
        let _ = authorizationStatuses.removeFirst()
        delegate?.locationManager?(CLLocationManager(), didChangeAuthorization: _authorizationStatus)
    }

    func requestAlwaysAuthorization() {
        let _ = authorizationStatuses.removeFirst()
        delegate?.locationManager?(CLLocationManager(), didChangeAuthorization: _authorizationStatus)
    }

    func authorizationStatus() -> CLAuthorizationStatus {
        return _authorizationStatus
    }

    func locationServicesEnabled() -> Bool {
        return true
    }

    func significantLocationChangeMonitoringAvailable() -> Bool {
        return true
    }
}
