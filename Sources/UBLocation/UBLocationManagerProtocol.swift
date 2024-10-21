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
    var activityType: CLActivityType { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var showsBackgroundLocationIndicator: Bool { get set }
    // Starting / stopping updates
    func startUpdatingLocation()
    func stopUpdatingLocation()

#if !os(visionOS)
    var headingFilter: CLLocationDegrees { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    var monitoredRegions: Set<CLRegion> { get }
    var maximumRegionMonitoringDistance: CLLocationDistance { get }
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
    func startMonitoringVisits()
    func stopMonitoringVisits()
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
    func startUpdatingHeading()
    func stopUpdatingHeading()
#endif

    // Authorization
    func requestWhenInUseAuthorization()
#if !os(visionOS)
    func requestAlwaysAuthorization()
#endif
    
    var authorizationStatus: CLAuthorizationStatus { get }
    func locationServicesEnabled() -> Bool
    func significantLocationChangeMonitoringAvailable() -> Bool
#if !os(visionOS)
    func isMonitoringAvailable(for regionClass: AnyClass) -> Bool
#endif
}

extension CLLocationManager: UBLocationManagerProtocol {
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
