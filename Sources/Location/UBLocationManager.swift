//
//  UBLocationManager.swift
//  UBFoundation
//
//  Created by Joseph El Mallah & Zeno Koller on 16.01.20.
//  Copyright © 2020 Ubique. All rights reserved.
//

import CoreLocation
import Foundation

/// An object defining methods that handle events related to GPS location.
public protocol UBLocationManagerDelegate: CLLocationManagerDelegate {
    /// Notifies the delegate that the desired usage requires a permission level (`permission`) which has not been granted.
    func locationManager(_ manager: UBLocationManager, requiresPermission permission: UBLocationManager.LocationMonitoringUsage.AuthorizationLevel)
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didUpdateLocations locations: [CLLocation])
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didUpdateHeading newHeading: CLHeading)
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didVisit visit: CLVisit)
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didFailWithError error: Error)
}

extension UBLocationManagerDelegate {
    func locationManager(_: UBLocationManager, didUpdateLocations _: [CLLocation]) {}
    func locationManager(_: UBLocationManager, didVisit _: CLVisit) {}
}

/// A convenience wrapper for `CLLocationManager` which facilitates obtaining the required authorization
/// for the desired usage (defined as a set of `UBLocationManager.LocationMonitoringUsage`)
public class UBLocationManager: NSObject {
    /// :nodoc:
    public weak var delegate: UBLocationManagerDelegate?

    /// The desired location accuracy of the underlying `CLLocationManager`
    public var desiredAccuracy: CLLocationAccuracy {
        get { locationManager.desiredAccuracy }
        set {
            locationManager.desiredAccuracy = newValue
        }
    }

    /// The distance filter of the underlying `CLLocationManager`
    public var distanceFilter: CLLocationDistance {
        get { locationManager.distanceFilter }
        set {
            locationManager.distanceFilter = newValue
        }
    }

    /// The heading filter of the underlying `CLLocationManager`
    public var headingFilter: CLLocationDegrees {
        get { locationManager.headingFilter }
        set {
            locationManager.headingFilter = newValue
        }
    }

    /// The amount of seconds after which a location obtained by `CLLocationManager` should be considered stale
    /// and not trigger a call of the `locationManager(_:didUpdateLocations)` delegate method
    public var maximumLastLocationTimestampSeconds: UInt = 3600

    var timeout: TimeInterval = 2
    private var locationTimer: Timer?
    var timedOut: Bool = false

    /// Does the location manager have the required authorization level for the desired `usage`?
    public var hasRequiredAuthorizationLevel: Bool {
        Self.hasRequiredAuthorizationLevel(forUsage: usage)
    }

    /// Does the location manager have the required authorization level for `usage`?
    public static func hasRequiredAuthorizationLevel(forUsage usage: LocationMonitoringUsage) -> Bool {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        switch authorizationStatus {
        case .authorizedAlways:
            return true
        case .authorizedWhenInUse:
            guard usage.minimumAuthorizationLevelRequired == .whenInUse else {
                return false
            }
            return true
        case .denied,
             .restricted:
            return false
        case .notDetermined:
            return false
        @unknown default:
            fatalError()
        }
    }

    private(set) lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.distanceFilter = kCLDistanceFilterNone
        manager.headingFilter = kCLHeadingFilterNone
        return manager
    }()

    /// The desired usage for this location manager
    public let usage: LocationMonitoringUsage

    // MARK: - Initialization

    /// Creates a `LocationManager` which facilitates obtaining the required location permissions for the desired usage
    ///
    /// - Parameters:
    ///   - usage: The desired usage. Can also be an array, e.g. [.location, .heading]
    public init(usage: LocationMonitoringUsage = .location) {
        self.usage = usage
    }

    /// Start monitoring location service events (varies by `usage`)
    ///
    /// - Parameters:
    ///   - canAskForPermission: Whether the location manager can ask for the required permission on its own behalf
    public func startLocationMonitoring(canAskForPermission: Bool) {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        let minimumAuthorizationLevelRequired = usage.minimumAuthorizationLevelRequired
        switch authorizationStatus {
        case .authorizedAlways:
            startLocationMonitoringWithoutChecks()
        case .authorizedWhenInUse:
            guard minimumAuthorizationLevelRequired == .whenInUse else {
                if canAskForPermission {
                    locationManager.requestAlwaysAuthorization()
                }
                return
            }
            startLocationMonitoringWithoutChecks()
        case .denied,
             .restricted:
            stopLocationMonitoring()
            delegate?.locationManager(self, requiresPermission: minimumAuthorizationLevelRequired)
        case .notDetermined:
            stopLocationMonitoring()
            if canAskForPermission {
                switch minimumAuthorizationLevelRequired {
                case .always:
                    locationManager.requestAlwaysAuthorization()
                case .whenInUse:
                    locationManager.requestWhenInUseAuthorization()
                }
            }
            delegate?.locationManager(self, requiresPermission: minimumAuthorizationLevelRequired)
        @unknown default:
            fatalError()
        }
    }

    /// Stops monitoring all location service events
    public func stopLocationMonitoring() {
        timedOut = false
        locationTimer?.invalidate()
        locationTimer = nil

        if usage.contains(.location) {
            locationManager.stopUpdatingLocation()
        }
        if usage.contains(.significantChange), CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.stopMonitoringSignificantLocationChanges()
        }
        if usage.contains(.visits) {
            locationManager.stopMonitoringVisits()
        }
        if usage.contains(.heading) {
            locationManager.stopUpdatingHeading()
        }
    }

    /// :nodoc:
    private func startLocationMonitoringWithoutChecks() {
        guard CLLocationManager.locationServicesEnabled() else {
            delegate?.locationManager(self, requiresPermission: usage.minimumAuthorizationLevelRequired)
            return
        }

        if usage.contains(.location) {
            locationManager.startUpdatingLocation()
            locationTimer?.invalidate()
            locationTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] _ in
                guard let self = self, let location = self.locationManager.location, location.timestamp > Date(timeIntervalSinceNow: -Double(self.maximumLastLocationTimestampSeconds)) else { return }
                self.timedOut = true
                self.delegate?.locationManager(self, didUpdateLocations: [location])
            })
        }
        if usage.contains(.significantChange), CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
        }
        if usage.contains(.visits) {
            locationManager.startMonitoringVisits()
        }
        if usage.contains(.heading) {
            locationManager.startUpdatingHeading()
        }
    }
}

extension UBLocationManager: CLLocationManagerDelegate {
    public func locationManager(_: CLLocationManager, didChangeAuthorization _: CLAuthorizationStatus) {
        startLocationMonitoring(canAskForPermission: false)
    }

    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let results: [CLLocation]

        if timedOut {
            results = locations
        } else {
            results = locations.filter { (location) -> Bool in
                location.horizontalAccuracy < desiredAccuracy
            }
        }
        if !results.isEmpty {
            locationTimer?.invalidate()
            locationTimer = nil
            delegate?.locationManager(self, didUpdateLocations: locations)
        }
    }

    public func locationManager(_: CLLocationManager, didVisit visit: CLVisit) {
        delegate?.locationManager(self, didVisit: visit)
    }

    public func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationManager(self, didUpdateHeading: newHeading)
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        if (error as! CLError).code == CLError.denied {
            // Location updates are not authorized.
            stopLocationMonitoring()
        }

        // This might be some temporary error. Just report it but do not stop
        // monitoring as it could be some temporary error and we just have to
        // wait for the next event
        delegate?.locationManager(self, didFailWithError: error)
    }
}

extension UBLocationManager {
    /// Defines the usage for `UBLocationManager`. Can be a combination of the defined options.
    public struct LocationMonitoringUsage: OptionSet {
        public let rawValue: UInt8

        /// Monitors location updates
        public static let location = LocationMonitoringUsage(rawValue: 1 << 0)
        /// Monitors significant location changes
        public static let significantChange = LocationMonitoringUsage(rawValue: 1 << 2)
        /// Monitors visits
        public static let visits = LocationMonitoringUsage(rawValue: 1 << 3)
        /// Monitors heading
        public static let heading = LocationMonitoringUsage(rawValue: 1 << 4)

        public init(rawValue: UInt8) {
            switch rawValue {
            case 1 << 2:
                self = .significantChange
            case 1 << 3:
                self = .visits
            case 1 << 4:
                self = .heading
            default:
                self = .location
            }
        }

        /// An authorization level granted by the user which allows starting location services
        public enum AuthorizationLevel: Int {
            /// User authorized the app to start location services while it is in use
            case whenInUse
            /// User authorized the app to start location services at any time
            case always
        }

        /// :nodoc:
        public var minimumAuthorizationLevelRequired: AuthorizationLevel {
            if contains(.significantChange) || contains(.visits) {
                return AuthorizationLevel.always
            } else {
                return AuthorizationLevel.whenInUse
            }
        }
    }
}
