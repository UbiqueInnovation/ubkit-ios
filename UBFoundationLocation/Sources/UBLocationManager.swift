//
//  UBLocationManager.swift
//  UBFoundation
//
//  Created by Joseph El Mallah & Zeno Koller on 16.01.20.
//  Copyright © 2020 Ubique. All rights reserved.
//

import CoreLocation
import Foundation
import UBFoundation

/// An object defining methods that handle events related to GPS location.
public protocol UBLocationManagerDelegate: CLLocationManagerDelegate {
    /// Notifies the delegate that the permission level for the desired usage has been granted.
    func locationManager(_ manager: UBLocationManager, grantedPermission permission: UBLocationManager.LocationMonitoringUsage.AuthorizationLevel)
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

public extension UBLocationManagerDelegate {
    func locationManager(_: UBLocationManager, grantedPermission _: UBLocationManager.LocationMonitoringUsage.AuthorizationLevel) {}
    func locationManager(_: UBLocationManager, didUpdateLocations _: [CLLocation]) {}
    func locationManager(_: UBLocationManager, didVisit _: CLVisit) {}
}

/// A convenience wrapper for `CLLocationManager` which facilitates obtaining the required authorization
/// for the desired usage (defined as a set of `UBLocationManager.LocationMonitoringUsage`)
open class UBLocationManager: NSObject {

    /// :nodoc:
    public weak var delegate: UBLocationManagerDelegate? {
        didSet {
            guard let delegate = delegate else { return }

            if let lastLocation = lastLocation {
                delegate.locationManager(self, didUpdateLocations: [lastLocation])
            }
            if let lastHeading = lastHeading {
                delegate.locationManager(self, didUpdateHeading: lastHeading)
            }
        }
    }

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

    /// The activity type of the underlying `CLLocationManager`
    public var activityType: CLActivityType {
        get { locationManager.activityType }
        set {
            locationManager.activityType = newValue
        }
    }

    /// Indicates whether the app should receive location updates when suspended.
    /// Setting this to `true` requires setting `UIBackgroundModes` to `location` in `Info.plist`
    public var allowsBackgroundLocationUpdates: Bool {
        get { locationManager.allowsBackgroundLocationUpdates }
        set {
            locationManager.allowsBackgroundLocationUpdates = newValue
        }
    }

    /// Indicates whether the location manager object may pause location updates to save battery.
    /// The default value is `true`.
    public var pausesLocationUpdatesAutomatically: Bool {
        get { locationManager.pausesLocationUpdatesAutomatically }
        set {
            locationManager.pausesLocationUpdatesAutomatically = newValue
        }
    }

    /// Does this location manager use the location in the background?
    public private(set) var usesLocationInBackground: Bool = false

    /// The amount of seconds after which a location obtained by `CLLocationManager` should be considered stale
    /// and not trigger a call of the `locationManager(_:didUpdateLocations)` delegate method
    public var maximumLastLocationTimestampSeconds: UInt = 3600

    /// For usage `.location`, the maximum time to wait for a location update from the underlying location manager.
    /// If no update has happened, we call `locationManager(_:didUpdateLocations)` with the most recent
    /// location from the underlying location manager, if it is not older than maximumLastLocationTimestampSeconds
    public private(set) var timeout: TimeInterval
    /// The default value for `timeout`
    public static var defaultTimeout: TimeInterval = 2
    /// :nodoc:
    private var locationTimer: Timer?
    /// :nodoc:
    var timedOut: Bool = false

    /// Does the location manager have the required authorization level for the desired `usage`?
    public var hasRequiredAuthorizationLevel: Bool {
        Self.hasRequiredAuthorizationLevel(forUsage: usage, withBackground: usesLocationInBackground)
    }

    /// Does the location manager have the required authorization level for `usage`?
    public static func hasRequiredAuthorizationLevel(forUsage usage: LocationMonitoringUsage, withBackground background: Bool = false) -> Bool {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        switch authorizationStatus {
        case .authorizedAlways:
            return true
        case .authorizedWhenInUse:
            let requiredAuthorizationLevel = usage.minimumAuthorizationLevelRequired(background)
            guard requiredAuthorizationLevel == .whenInUse else {
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

    /// The underlying location manager
    private(set) var locationManager: UBLocationManagerProtocol

    /// The desired usage for this location manager
    public let usage: LocationMonitoringUsage

    /// The last location update received from the system.
    public private(set) var lastLocation: CLLocation?

    /// The last heading update received from the system.
    public private(set) var lastHeading: CLHeading?

    // MARK: - Initialization

    /// Creates a `UBLocationManager` which facilitates obtaining the required location permissions for the desired usage
    ///
    /// - Parameters:
    ///   - usage: The desired usage. Can also be an array, e.g. [.location, .heading]
    ///   - locationManager: The underlying location manager
    ///   - timeout: The maximum time to wait for a location update from the underlying location manager. If
    ///   no update has happened, we call `locationManager(_:didUpdateLocations)` with the most recent
    ///   location from the underlying location manager, if it is not older than maximumLastLocationTimestampSeconds
    public init(usage: LocationMonitoringUsage = .location,
                locationManager: UBLocationManagerProtocol = CLLocationManager(),
                timeout: TimeInterval = UBLocationManager.defaultTimeout) {
        self.usage = usage
        self.locationManager = locationManager
        self.timeout = timeout

        super.init()

        setupLocationManager()
    }

    /// Applies the initial configuration for the location manager
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.activityType = .fitness

        // Only applies if the `Always` authorization is granted.
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
        }
    }

    /// Start monitoring location service events (varies by `usage`)
    ///
    /// - Parameters:
    ///   - canAskForPermission: Whether the location manager can ask for the required permission on its own behalf
    ///   - withBackground: If set, overrides the `usesLocationInBackground` property
    public func startLocationMonitoring(canAskForPermission: Bool, withBackground background: Bool? = nil) {
        func requestPermission(for authorizationLevel: LocationMonitoringUsage.AuthorizationLevel) {
            switch authorizationLevel {
            case .always:
                locationManager.requestAlwaysAuthorization()
            case .whenInUse:
                locationManager.requestWhenInUseAuthorization()
            }
        }

        if let background = background {
            self.usesLocationInBackground = background
        }
        let authorizationStatus = locationManager.authorizationStatus()
        let minimumAuthorizationLevelRequired = usage.minimumAuthorizationLevelRequired(usesLocationInBackground)
        switch authorizationStatus {
        case .authorizedAlways:
            startLocationMonitoringWithoutChecks()
        case .authorizedWhenInUse:
            guard minimumAuthorizationLevelRequired == .whenInUse else {
                if canAskForPermission {
                    requestPermission(for: minimumAuthorizationLevelRequired)
                }
                delegate?.locationManager(self, requiresPermission: minimumAuthorizationLevelRequired)
                return
            }
            startLocationMonitoringWithoutChecks()
        case .denied,
             .restricted:
            stopLocationMonitoring()
            if canAskForPermission {
                requestPermission(for: minimumAuthorizationLevelRequired)
            }
            delegate?.locationManager(self, requiresPermission: minimumAuthorizationLevelRequired)
        case .notDetermined:
            stopLocationMonitoring()
            if canAskForPermission {
                requestPermission(for: minimumAuthorizationLevelRequired)
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
        if usage.contains(.significantChange), locationManager.significantLocationChangeMonitoringAvailable() {
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
        guard locationManager.locationServicesEnabled() else {
            let requiredAuthorizationLevel = usage.minimumAuthorizationLevelRequired(usesLocationInBackground)
            delegate?.locationManager(self, requiresPermission: requiredAuthorizationLevel)
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
        if usage.contains(.significantChange), locationManager.significantLocationChangeMonitoringAvailable() {
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
    public func locationManager(_: CLLocationManager, didChangeAuthorization authorization: CLAuthorizationStatus) {
        startLocationMonitoring(canAskForPermission: false)

        if hasRequiredAuthorizationLevel {
            let permission: LocationMonitoringUsage.AuthorizationLevel = authorization == .authorizedAlways ? .always : .whenInUse
            delegate?.locationManager(self, grantedPermission: permission)
        }
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
        if let lastLocation = results.last {
            self.lastLocation = lastLocation

            locationTimer?.invalidate()
            locationTimer = nil
            delegate?.locationManager(self, didUpdateLocations: results)
        }
    }

    public func locationManager(_: CLLocationManager, didVisit visit: CLVisit) {
        delegate?.locationManager(self, didVisit: visit)
    }

    public func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading
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

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        /// Monitors location updates
        public static let location = LocationMonitoringUsage(rawValue: 1 << 0)
        /// Monitors significant location changes
        public static let significantChange = LocationMonitoringUsage(rawValue: 1 << 2)
        /// Monitors visits
        public static let visits = LocationMonitoringUsage(rawValue: 1 << 3)
        /// Monitors heading
        public static let heading = LocationMonitoringUsage(rawValue: 1 << 4)

        /// An authorization level granted by the user which allows starting location services
        public enum AuthorizationLevel: Int {
            /// User authorized the app to start location services while it is in use
            case whenInUse
            /// User authorized the app to start location services at any time
            case always
        }

        /// :nodoc:
        public func minimumAuthorizationLevelRequired(_ backgroundUsage: Bool = false) -> AuthorizationLevel {
            if contains(.significantChange) || contains(.visits) || backgroundUsage {
                return AuthorizationLevel.always
            } else {
                return AuthorizationLevel.whenInUse
            }
        }
    }
}
