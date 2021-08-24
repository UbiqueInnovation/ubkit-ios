//
//  UBLocationManager.swift
//  UBFoundation
//
//  Created by Joseph El Mallah & Zeno Koller on 16.01.20.
//  Copyright © 2020 Ubique. All rights reserved.
//

import CoreLocation
import UBFoundation

/// An object defining methods that handle events related to GPS location.
public protocol UBLocationManagerDelegate: CLLocationManagerDelegate {
    /// Notifies the delegate that the permission level for the desired usage has been granted.
    func locationManager(_ manager: UBLocationManager, grantedPermission permission: UBLocationManager.AuthorizationLevel, accuracy: UBLocationManager.AccuracyLevel)
    func locationManager(permissionDeniedFor manager: UBLocationManager)
    /// Notifies the delegate that the desired usage requires a permission level (`permission`) which has not been granted.
    func locationManager(_ manager: UBLocationManager, requiresPermission permission: UBLocationManager.AuthorizationLevel)
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didUpdateLocations locations: [CLLocation])
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didUpdateHeading newHeading: CLHeading)
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didVisit visit: CLVisit)
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didFailWithError error: Error)

    /// If set, the locations returned for this delegate will be filtered for the given accuracy
    var locationManagerFilterAccuracy: CLLocationAccuracy? { get }
}

public extension UBLocationManagerDelegate {
    func locationManager(permissionDeniedFor _: UBLocationManager) {}
    func locationManager(_ manager: UBLocationManager, grantedPermission permission: UBLocationManager.AuthorizationLevel, accuracy: UBLocationManager.AccuracyLevel) {}
    func locationManager(_: UBLocationManager, didUpdateLocations _: [CLLocation]) {}
    func locationManager(_: UBLocationManager, didUpdateHeading _: CLHeading) {}
    func locationManager(_: UBLocationManager, didVisit _: CLVisit) {}
}

/// A convenience wrapper for `CLLocationManager` which facilitates obtaining the required authorization
/// for the desired usage (defined as a set of `UBLocationManager.LocationMonitoringUsage`)
public class UBLocationManager: NSObject {
    /// The shared location manager.
    public static let shared = UBLocationManager()

    /// :nodoc:
    private var delegateWrappers: [ObjectIdentifier: UBLocationManagerDelegateWrapper] = [:]

    private var delegates: [UBLocationManagerDelegate] {
        delegateWrappers.values.compactMap { $0.delegate }
    }

    private var permissionRequestCallback : ((LocationPermissionRequestResult) -> ())?
    private var permissionRequestUsage : LocationMonitoringUsage?

    @UBUserDefault(key: "UBLocationManager_askedForAlwaysAtLeastOnce", defaultValue: false)
    private var askedForAlwaysPermissionAtLeastOnce : Bool

    /// :nodoc:
    public enum LocationPermissionRequestResult {
        /// Location permission was obtained successfully
        case success
        /// Location permission was not obtained
        case failure
        /// Location permission was not obtained and the user needs to be prompted the settings
        case showSettings
    }

    /// The union of the usages for all the delegaets
    private var usage: LocationMonitoringUsage {
        delegateWrappers.values
            .map { $0.usage }
            .reduce([]) { $0.union($1) }
    }

    /// Allows logging all the changes in authorization status, separately from any delegates
    public var logLocationPermissionChange: ((CLAuthorizationStatus) -> Void)?

    /// The desired location accuracy of the underlying `CLLocationManager`
    public var desiredAccuracy: CLLocationAccuracy {
        get { locationManager.desiredAccuracy }
        set {
            logger.error("UBLocationManager:desiredAccuracy:set" + String(newValue), accessLevel: .public)
            locationManager.desiredAccuracy = newValue
        }
    }

    /// The accuracy used for filtering points. If not set, `desiredAccuracy` will be used instead.
    public var filteredAccuracy: CLLocationAccuracy?

    /// The distance filter of the underlying `CLLocationManager`
    public var distanceFilter: CLLocationDistance {
        get { locationManager.distanceFilter }
        set {
            logger.error("UBLocationManager:distanceFilter:set" + String(newValue), accessLevel: .public)
            locationManager.distanceFilter = newValue
        }
    }

    public var accuracyLevel: UBLocationManager.AccuracyLevel {
        if #available(iOS 14.0, *) {
            return (locationManager as? CLLocationManager)?.accuracyAuthorization.accuracyLevel ?? .full
        } else {
            return .full
        }
    }

    /// The heading filter of the underlying `CLLocationManager`
    public var headingFilter: CLLocationDegrees {
        get { locationManager.headingFilter }
        set {
            logger.error("UBLocationManager:headingFilter:set" + String(newValue), accessLevel: .public)
            locationManager.headingFilter = newValue
        }
    }

    /// The activity type of the underlying `CLLocationManager`
    public var activityType: CLActivityType {
        get { locationManager.activityType }
        set {
            logger.error("UBLocationManager:activityType:set" + String(newValue.rawValue), accessLevel: .public)
            locationManager.activityType = newValue
        }
    }

    /// Indicates whether the app should receive location updates when suspended.
    /// Setting this to `true` requires setting `UIBackgroundModes` to `location` in `Info.plist`
    public var allowsBackgroundLocationUpdates: Bool {
        get { locationManager.allowsBackgroundLocationUpdates }
        set {
            logger.error("UBLocationManager:allowsBackgroundLocationUpdates:set" + String(newValue), accessLevel: .public)
            locationManager.allowsBackgroundLocationUpdates = newValue
        }
    }

    /// Does this location manager use the location in the background?
    public var usesLocationInBackground: Bool {
        return usage.requiresBackgroundLocation
    }

    /// The amount of seconds after which a location obtained by `CLLocationManager` should be considered stale
    /// and not trigger a call of the `locationManager(_:didUpdateLocations)` delegate method
    public var maximumLastLocationTimestampSeconds: UInt = 3600

    /// For usage `.location`, the maximum time to wait for a location update from the underlying location manager.
    /// If no update has happened, we call `locationManager(_:didUpdateLocations)` with the most recent
    /// location from the underlying location manager, if it is not older than maximumLastLocationTimestampSeconds
    public var timeout: TimeInterval {
        didSet {
            startLocationTimer()
        }
    }

    /// The default value for `timeout`
    public static var defaultTimeout: TimeInterval = 2
    /// :nodoc:
    private var locationTimer: Timer?
    /// :nodoc:
    var timedOut: Bool = false

    /// Does the location manager have the required authorization level for `usage`?
    public static func hasRequiredAuthorizationLevel(forUsage usage: LocationMonitoringUsage) -> Bool {
        let authorizationStatus = CLLocationManager.authorizationStatus()

        let logger = try! UBLogger(category: "\(UBLocationManager.self)")
        logger.error("UBLocationManager:hasRequiredAuthorizationLevel = " + String(authorizationStatus.rawValue), accessLevel: .public)

        switch authorizationStatus {
        case .authorizedAlways:
            return true
        case .authorizedWhenInUse:
            let requiredAuthorizationLevel = usage.minimumAuthorizationLevelRequired
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

    /// The last location update received from the system.
    public private(set) var lastLocation: CLLocation?

    /// The last heading update received from the system.
    public private(set) var lastHeading: CLHeading?

    let logger: UBFoundation.UBLogger = try! UBLogger(category: "\(UBLocationManager.self)")

    // MARK: - Initialization

    /// Creates a `UBLocationManager` which facilitates obtaining location permissions
    ///
    /// - Parameters:
    ///   - locationManager: The underlying location manager
    init(locationManager: UBLocationManagerProtocol = CLLocationManager()) {
        self.locationManager = locationManager
        timeout = Self.defaultTimeout

        super.init()

        setupLocationManager()
    }

    /// Applies the initial configuration for the location manager
    private func setupLocationManager() {
        logger.error("UBLocationManager:setupLocationManager", accessLevel: .public)

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.activityType = .other
        locationManager.pausesLocationUpdatesAutomatically = false

        // Only applies if the "Always" authorization is granted and `allowsBackgroundLocationUpdates`
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
        }
    }

    /// Start monitoring location service events (varies by `usage`)
    ///
    /// - Parameters:
    ///   - usage: The desired usage. Can also be an array, e.g. `[.location(background: false), .heading(background: true)]`
    ///   - canAskForPermission: Whether the location manager can ask for the required permission on its own behalf
    public func startLocationMonitoring(for usage: LocationMonitoringUsage, delegate: UBLocationManagerDelegate, canAskForPermission: Bool) {
        logger.error("UBLocationManager:startLocationMonitoring for usage: " + String(usage.rawValue), accessLevel: .public)

        let wrapper = UBLocationManagerDelegateWrapper(delegate, usage: usage)
        let id = ObjectIdentifier(delegate)
        delegateWrappers[id] = wrapper

        let authorizationStatus = locationManager.authorizationStatus()
        let minimumAuthorizationLevelRequired = usage.minimumAuthorizationLevelRequired
        switch authorizationStatus {
        case .authorizedAlways:
            startLocationMonitoringWithoutChecks(delegate)
        case .authorizedWhenInUse:
            guard minimumAuthorizationLevelRequired == .whenInUse else {
                if canAskForPermission {
                    requestPermission(for: minimumAuthorizationLevelRequired)
                }
                delegate.locationManager(self, requiresPermission: minimumAuthorizationLevelRequired)
                return
            }
            startLocationMonitoringWithoutChecks(delegate)
        case .denied,
             .restricted:
            stopLocationMonitoring()
            if canAskForPermission {
                requestPermission(for: minimumAuthorizationLevelRequired)
            }
            delegate.locationManager(self, requiresPermission: minimumAuthorizationLevelRequired)
        case .notDetermined:
            stopLocationMonitoring()
            if canAskForPermission {
                requestPermission(for: minimumAuthorizationLevelRequired)
            }
            delegate.locationManager(self, requiresPermission: minimumAuthorizationLevelRequired)
        @unknown default:
            fatalError()
        }
    }

    /// Stops monitoring location service events and removes the delegate
    public func stopLocationMonitoring(forDelegate delegate: UBLocationManagerDelegate) {
        logger.error("UBLocationManager:stopLocationMonitoring", accessLevel: .public)

        let id = ObjectIdentifier(delegate)
        if let delegate = delegateWrappers.removeValue(forKey: id) {
            stopLocationMonitoring(delegate.usage)
        }

        self.startLocationMonitoringForAllDelegates()

        assert(!delegateWrappers.isEmpty || usage == [])
    }

    /// Stops monitoring all location service events
    private func stopLocationMonitoring(_ usage: LocationMonitoringUsage? = nil) {
        let usage = usage ?? self.usage

        timedOut = false
        locationTimer?.invalidate()
        locationTimer = nil

        if usage.containsLocation {
            logger.error("locationManager:stopLocationMonitoring().stopUpdatingLocation()", accessLevel: .public)
            locationManager.stopUpdatingLocation()
        }
        if usage.contains(.significantChange), locationManager.significantLocationChangeMonitoringAvailable() {
            logger.error("locationManager:stopLocationMonitoring().stopMonitoringSignificantLocationChanges()", accessLevel: .public)
            locationManager.stopMonitoringSignificantLocationChanges()
        }
        if usage.contains(.visits) {
            logger.error("locationManager:stopLocationMonitoring().stopMonitoringVisits()", accessLevel: .public)
            locationManager.stopMonitoringVisits()
        }
        if usage.containsHeading {
            logger.error("locationManager:stopLocationMonitoring().stopUpdatingHeading()", accessLevel: .public)
            locationManager.stopUpdatingHeading()
        }
    }

    /// Permission request to get state of location permission (varies by `usage`)
    ///
    /// - Parameters:
    ///   - usage: The desired usage.
    ///   - callback: Asynchronous callback with result.
    public func requestPermission(for usage: LocationMonitoringUsage, callback: @escaping ((LocationPermissionRequestResult) -> ())) {
        logger.error("UBLocationManager:requestPermission:" + String(usage.rawValue), accessLevel: .public)

        // if it's already running, callback .failed & continue
        if self.permissionRequestCallback != nil {
            self.permissionRequestCallback?(.failure)
            self.permissionRequestCallback = nil
            self.permissionRequestUsage = nil
        }

        let authorizationStatus = locationManager.authorizationStatus()
        let minimumAuthorizationLevelRequired = usage.minimumAuthorizationLevelRequired

        switch authorizationStatus {
        case .authorizedAlways:
            callback(.success)
        case .authorizedWhenInUse:
            guard minimumAuthorizationLevelRequired == .whenInUse else {
                // can only ask once
                if(minimumAuthorizationLevelRequired == .always && self.askedForAlwaysPermissionAtLeastOnce) {
                    callback(.showSettings)
                    return
                }

                self.permissionRequestUsage = usage
                self.permissionRequestCallback = callback
                requestPermission(for: minimumAuthorizationLevelRequired)
                return
            }

            callback(.success)
        case .denied, .restricted:
            callback(.showSettings)

        case .notDetermined:
            self.permissionRequestUsage = usage
            self.permissionRequestCallback = callback
            self.requestPermission(for: minimumAuthorizationLevelRequired)

        @unknown default:
            fatalError()
        }
    }

    /// :nodoc:
    private func startLocationMonitoringWithoutChecks(_ delegate: UBLocationManagerDelegate) {

        guard locationManager.locationServicesEnabled() else {
            logger.error("locationManager.startLocationMonitoringWithoutChecks() location services not enabled", accessLevel: .public)

            let requiredAuthorizationLevel = usage.minimumAuthorizationLevelRequired
            delegate.locationManager(self, requiresPermission: requiredAuthorizationLevel)
            return
        }

        if usage.containsLocation {
            logger.error("locationManager.startLocationMonitoringWithoutChecks().startUpdatingLocation()", accessLevel: .public)
            locationManager.startUpdatingLocation()
            startLocationTimer()
        }
        if usage.contains(.significantChange), locationManager.significantLocationChangeMonitoringAvailable() {
            logger.error("locationManager.startLocationMonitoringWithoutChecks().startMonitoringSignificantLocationChanges()", accessLevel: .public)
            locationManager.startMonitoringSignificantLocationChanges()
        }
        if usage.contains(.visits) {
            logger.error("locationManager.startLocationMonitoringWithoutChecks().startMonitoringVisits()", accessLevel: .public)
            locationManager.startMonitoringVisits()
        }
        if usage.containsHeading {
            logger.error("locationManager.startLocationMonitoringWithoutChecks().startUpdatingHeading()", accessLevel: .public)
            locationManager.startUpdatingHeading()
        }
    }

    private func startLocationTimer() {
        locationTimer?.invalidate()
        locationTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] _ in
            guard let self = self, let location = self.locationManager.location, location.timestamp > Date(timeIntervalSinceNow: -Double(self.maximumLastLocationTimestampSeconds)) else { return }
            self.timedOut = true
            self.logger.error("locationManager:locationTimer fired. Sending last location.", accessLevel: .public)

            self.notifyDelegates(withLocations: [location])
        })
    }

    private func startLocationMonitoringForAllDelegates() {
        logger.error("locationManager.startLocationMonitoringForAllDelegates() for " + String(delegateWrappers.count) + " delegates", accessLevel: .public)

        for wrapper in delegateWrappers.values {
            if let delegate = wrapper.delegate {
                startLocationMonitoring(for: wrapper.usage, delegate: delegate, canAskForPermission: false)
            }
        }
    }

    /// request permission from the location manager
    func requestPermission(for authorizationLevel: AuthorizationLevel) {
        switch authorizationLevel {
        case .always:
            logger.error("locationManager.requestAlwaysAuthorization()", accessLevel: .public)
            locationManager.requestAlwaysAuthorization()
            self.askedForAlwaysPermissionAtLeastOnce = true
        case .whenInUse:
            logger.error("locationManager.requestWhenInUseAuthorization()", accessLevel: .public)
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

extension UBLocationManager: CLLocationManagerDelegate {

    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        logger.error("locationManager:locationManagerDidPauseLocationUpdates", accessLevel: .public)
    }

    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        logger.error("locationManager:locationManagerDidResumeLocationUpdates", accessLevel: .public)
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization authorization: CLAuthorizationStatus) {
        logger.error("locationManager:didChangeAuthorization: " + String(authorization.rawValue), accessLevel: .public)

        logLocationPermissionChange?(authorization)

        self.startLocationMonitoringForAllDelegates()

        if Self.hasRequiredAuthorizationLevel(forUsage: usage) {
            let permission: AuthorizationLevel = authorization == .authorizedAlways ? .always : .whenInUse

            for delegate in delegates {
                delegate.locationManager(self, grantedPermission: permission, accuracy: accuracyLevel)
            }
        }
        if authorization == .denied {
            for delegate in delegates {
                delegate.locationManager(permissionDeniedFor: self)
            }
        }

        // permission request callbacks
        if let usage = self.permissionRequestUsage,
           let callback = self.permissionRequestCallback {
            let hasRequiredLevel = Self.hasRequiredAuthorizationLevel(forUsage: usage)
            callback(hasRequiredLevel ? .success : .failure)

            self.permissionRequestCallback = nil
            self.permissionRequestUsage = nil
        }
    }

    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        // remove invalid locations
        let results: [CLLocation] = locations.filter { (location) -> Bool in
            // A negative value indicates that the latitude and longitude are invalid
            location.horizontalAccuracy >= 0 &&
                // GPS  may return 0 to indicate no location
                location.coordinate.latitude != 0 && location.coordinate.longitude != 0
        }

        if !results.isEmpty {
            locationTimer?.invalidate()
            locationTimer = nil
            logger.error("locationManager:didUpdateLocations: Locations (after filtering) empty", accessLevel: .public)
        }

        notifyDelegates(withLocations: results)
    }

    private func notifyDelegates(withLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            logger.error("locationManager:notifyDelegates: No location available", accessLevel: .public)
            return

        }
        self.lastLocation = lastLocation

        for delegate in delegates {
            let filteredLocations: [CLLocation]
            if let filteredAccuracy = delegate.locationManagerFilterAccuracy {
                let targetAccuracy = (filteredAccuracy > 0 ? filteredAccuracy : 10)
                filteredLocations = locations.filter { $0.horizontalAccuracy < targetAccuracy }
            } else {
                filteredLocations = locations
            }

            if filteredLocations.count == 0 {
                logger.error("locationManager.notifyDelegates() notifying empty array", accessLevel: .public)
            }

            delegate.locationManager(self, didUpdateLocations: filteredLocations)
        }

        if delegates.count == 0 {
            logger.error("locationManager.notifyDelegates() no delegates", accessLevel: .public)
        }
    }

    public func locationManager(_: CLLocationManager, didVisit visit: CLVisit) {
        for delegate in delegates {
            delegate.locationManager(self, didVisit: visit)
        }
    }

    public func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading
        for delegate in delegates {
            delegate.locationManager(self, didUpdateHeading: newHeading)
        }
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        logger.error("locationManager:didFailWithError: " + error.localizedDescription, accessLevel: .public)

        // This might be some temporary error. Just report it but do not stop
        // monitoring as it could be some temporary error and we just have to
        // wait for the next event
        for delegate in delegates {
            delegate.locationManager(self, didFailWithError: error)
        }
    }
}

extension UBLocationManager {
    /// An authorization level granted by the user which allows starting location services
    public enum AuthorizationLevel: Int {
        /// User authorized the app to start location services while it is in use
        case whenInUse
        /// User authorized the app to start location services at any time
        case always
    }

    /// Defines the level of accuracy granted by the user.
    public enum AccuracyLevel: Int {
        case reduced, full
    }

    /// Defines the usage for `UBLocationManager`. Can be a combination of the defined options.
    public struct LocationMonitoringUsage: OptionSet {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        /// :nodoc:
        public var requiresBackgroundLocation: Bool {
            return contains(.backgroundLocation) || contains(.backgroundHeading)
        }

        /// Monitors location
        public static func location(background: Bool) -> LocationMonitoringUsage {
            return background ? .backgroundLocation : .foregroundLocation
        }

        private static let foregroundLocation = LocationMonitoringUsage(rawValue: 1 << 0)
        private static let backgroundLocation = LocationMonitoringUsage(rawValue: 1 << 1)

        /// Monitors heading
        public static func heading(background: Bool) -> LocationMonitoringUsage {
            return background ? .backgroundHeading : .foregroundHeading
        }

        private static let foregroundHeading = LocationMonitoringUsage(rawValue: 1 << 3)
        private static let backgroundHeading = LocationMonitoringUsage(rawValue: 1 << 2)

        /// Monitors significant location changes
        public static let significantChange = LocationMonitoringUsage(rawValue: 1 << 4)
        /// Monitors visits
        public static let visits = LocationMonitoringUsage(rawValue: 1 << 5)

        /// :nodoc:
        public var minimumAuthorizationLevelRequired: AuthorizationLevel {
            if contains(.significantChange) || contains(.visits) || requiresBackgroundLocation {
                return AuthorizationLevel.always
            } else {
                return AuthorizationLevel.whenInUse
            }
        }

        /// :nodoc:
        public var containsLocation: Bool {
            contains(.location(background: true)) || contains(.location(background: false))
        }

        /// :nodoc:
        public var containsHeading: Bool {
            contains(.heading(background: true)) || contains(.heading(background: false))
        }
    }
}

fileprivate extension CLAccuracyAuthorization {
    var accuracyLevel: UBLocationManager.AccuracyLevel {
        switch self {
        case .fullAccuracy:
            return .full
        case .reducedAccuracy:
            return .reduced
        @unknown default:
            fatalError("Level of accuracy not handled")
        }
    }
}

