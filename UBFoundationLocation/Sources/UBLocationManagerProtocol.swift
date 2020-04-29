//
//  UBLocationManagerProtocol.swift
//  UBFoundation iOS Tests
//
//  Created by Zeno Koller on 17.01.20.
//

import CoreLocation
import Foundation

/// Enables supplying a mock location manager to `UBLocationManager`
public protocol UBLocationManagerProtocol {
    // Properties
    var location: CLLocation? { get }
    var delegate: CLLocationManagerDelegate? { get set }
    var distanceFilter: CLLocationDistance { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var headingFilter: CLLocationDegrees { get set }
    var activityType: CLActivityType { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    @available(iOS 11.0, *)
    var showsBackgroundLocationIndicator: Bool { get set }

    // Starting / stopping updates
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
    func startMonitoringVisits()
    func stopMonitoringVisits()
    func startUpdatingHeading()
    func stopUpdatingHeading()

    // Authorization
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()

    func authorizationStatus() -> CLAuthorizationStatus
    func locationServicesEnabled() -> Bool
    func significantLocationChangeMonitoringAvailable() -> Bool
}

extension CLLocationManager: UBLocationManagerProtocol {
    public func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    public func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    public func significantLocationChangeMonitoringAvailable() -> Bool {
        return CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
}
