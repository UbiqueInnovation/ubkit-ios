//
//  UBLocationManagerProtocol.swift
//  UBFoundation iOS Tests
//
//  Created by Zeno Koller on 17.01.20.
//  Copyright © 2020 Ubique. All rights reserved.
//

import CoreLocation

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
    var showsBackgroundLocationIndicator: Bool { get set }
    var monitoredRegions: Set<CLRegion> { get }
    var maximumRegionMonitoringDistance: CLLocationDistance { get }

    // Starting / stopping updates
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
    func startMonitoringVisits()
    func stopMonitoringVisits()
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
    func startUpdatingHeading()
    func stopUpdatingHeading()

    // Authorization
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()

    func authorizationStatus() -> CLAuthorizationStatus
    func locationServicesEnabled() -> Bool
    func significantLocationChangeMonitoringAvailable() -> Bool
    func isMonitoringAvailable(for regionClass: AnyClass) -> Bool
}

extension CLLocationManager: UBLocationManagerProtocol {
    public func authorizationStatus() -> CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }

    @available(*, deprecated, message: "locationServicesEnabled() not exposed to avoid use on main thread. Use CLLocationManager.locationServicesEnabled() directly if needed.")
    public func locationServicesEnabled() -> Bool {
        CLLocationManager.locationServicesEnabled()
    }

    public func significantLocationChangeMonitoringAvailable() -> Bool {
        CLLocationManager.significantLocationChangeMonitoringAvailable()
    }

    public func isMonitoringAvailable(for regionClass: AnyClass) -> Bool {
        CLLocationManager.isMonitoringAvailable(for: regionClass)
    }
}
