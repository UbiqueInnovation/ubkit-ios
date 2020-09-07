//
//  MockLocationManager.swift
//  UBFoundation iOS Tests
//
//  Created by Zeno Koller on 17.01.20.
//

import CoreLocation
import Foundation
import UBLocation

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

    weak var delegate: CLLocationManagerDelegate?
    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var headingFilter: CLLocationDegrees = kCLHeadingFilterNone
    var activityType: CLActivityType = .fitness
    var allowsBackgroundLocationUpdates: Bool = false
    var pausesLocationUpdatesAutomatically: Bool = false
    var showsBackgroundLocationIndicator: Bool = false

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
        _ = authorizationStatuses.removeFirst()
        delegate?.locationManager?(CLLocationManager(), didChangeAuthorization: _authorizationStatus)
    }

    func requestAlwaysAuthorization() {
        _ = authorizationStatuses.removeFirst()
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
