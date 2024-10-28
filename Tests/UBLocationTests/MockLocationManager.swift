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
    var authorizationStatuses: [CLAuthorizationStatus] = [] {
        didSet {
            delegate?.locationManagerDidChangeAuthorization?(CLLocationManager())
        }
    }

    var _authorizationStatus: CLAuthorizationStatus {
        guard let currentAuthorizationStatus = authorizationStatuses.first else {
            return .notDetermined
        }
        return currentAuthorizationStatus
    }

    var isUpdatingLocation: Bool = false

    var isMonitoringSignificantLocationChanges: Bool = false

#if !os(visionOS)
    var isMonitoringVisits: Bool = false

    var isUpdatingHeading: Bool = false

    var monitoredRegions: Set<CLRegion> = Set()
#endif

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

#if !os(visionOS)
    var maximumRegionMonitoringDistance: CLLocationDistance = CLLocationManager().maximumRegionMonitoringDistance
#endif

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

#if !os(visionOS)
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

    func startMonitoring(for region: CLRegion) {
        monitoredRegions.insert(region)
    }

    func stopMonitoring(for region: CLRegion) {
        monitoredRegions.remove(region)
    }

#endif

    // MARK: - Authorization

    func requestWhenInUseAuthorization() {
        _ = authorizationStatuses.removeFirst()
        delegate?.locationManagerDidChangeAuthorization?(CLLocationManager())
    }

#if !os(visionOS)

    func requestAlwaysAuthorization() {
        _ = authorizationStatuses.removeFirst()
        delegate?.locationManager?(CLLocationManager(), didChangeAuthorization: _authorizationStatus)
    }

#endif

    var authorizationStatus: CLAuthorizationStatus {
        _authorizationStatus
    }

    func locationServicesEnabled() -> Bool {
        true
    }

    func significantLocationChangeMonitoringAvailable() -> Bool {
        true
    }

    func isMonitoringAvailable(for regionClass: AnyClass) -> Bool {
        true
    }
}
