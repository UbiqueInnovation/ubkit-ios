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
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didEnterRegion region: CLRegion)
    /// :nodoc:
    func locationManager(_ manager: UBLocationManager, didExitRegion region: CLRegion)

    /// If set, the locations returned for this delegate will be filtered for the given accuracy
    var locationManagerFilterAccuracy: CLLocationAccuracy? { get }

    /// Time interval, after which delegate will be notified if no new location occured
    var locationManagerMaxFreshAge: TimeInterval? { get }

    /// Called if no new location update was sent for `locationMaxAge`
    func locationManager(_ manager: UBLocationManager, locationIsFresh: Bool)
}

public extension UBLocationManagerDelegate {
    func locationManager(permissionDeniedFor _: UBLocationManager) {}
    func locationManager(_: UBLocationManager, grantedPermission _: UBLocationManager.AuthorizationLevel, accuracy _: UBLocationManager.AccuracyLevel) {}
    func locationManager(_: UBLocationManager, didUpdateLocations _: [CLLocation]) {}
    func locationManager(_: UBLocationManager, didUpdateHeading _: CLHeading) {}
    func locationManager(_: UBLocationManager, didVisit _: CLVisit) {}
    func locationManager(_: UBLocationManager, didEnterRegion region: CLRegion) {}
    func locationManager(_: UBLocationManager, didExitRegion region: CLRegion) {}
    var locationManagerMaxFreshAge: TimeInterval? { nil }
    func locationManager(_: UBLocationManager, locationIsFresh _: Bool) {}
}

/// A convenience wrapper for `CLLocationManager` which facilitates obtaining the required authorization
/// for the desired usage (defined as a set of `UBLocationManager.LocationMonitoringUsage`)
public class UBLocationManager: NSObject {
    /// The shared location manager.
    public static let shared = UBLocationManager()

    /// :nodoc:
    private var delegateWrappers: [ObjectIdentifier: UBLocationManagerDelegateWrapper] = [:]

    private var delegates: [UBLocationManagerDelegate] {
        delegateWrappers.values.compactMap(\.delegate)
    }

    private var permissionRequestCallback: ((LocationPermissionRequestResult) -> Void)?
    private var permissionRequestUsage: Set<LocationMonitoringUsage>?

    @UBUserDefault(key: "UBLocationManager_askedForAlwaysAtLeastOnce", defaultValue: false)
    private var askedForAlwaysPermissionAtLeastOnce: Bool

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
    private var usage: Set<LocationMonitoringUsage> {
        delegateWrappers.values
            .map(\.usage)
            .reduce([]) { $0.union($1) }
    }

    /// Allows logging all the changes in authorization status, separately from any delegates
    public var logLocationPermissionChange: ((CLAuthorizationStatus) -> Void)?
    private var authorizationStatus: CLAuthorizationStatus? {
        didSet {
            if let authorizationStatus {
                authorizationCallbackTimers.values.forEach {
                    $0.invalidate()
                }
                authorizationCallbackTimers.removeAll()
                pendingAuthorizationStatusCallbacks.values.forEach {
                    $0(authorizationStatus)
                }
                pendingAuthorizationStatusCallbacks.removeAll()
            }
        }
    }

    private var pendingAuthorizationStatusCallbacks: [UUID: (CLAuthorizationStatus) -> Void] = [:]
    private var authorizationCallbackTimers: [UUID: Timer] = [:]
    private let timeoutTime: TimeInterval = 4

    /// The desired location accuracy of the underlying `CLLocationManager`
    public var desiredAccuracy: CLLocationAccuracy {
        get { locationManager.desiredAccuracy }
        set {
            locationManager.desiredAccuracy = newValue
        }
    }

    /// The accuracy used for filtering points. If not set, `desiredAccuracy` will be used instead.
    public var filteredAccuracy: CLLocationAccuracy?

    /// The distance filter of the underlying `CLLocationManager`
    public var distanceFilter: CLLocationDistance {
        get { locationManager.distanceFilter }
        set {
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

    /// The set of regions that are currently being monitored.
    public var monitoredRegions: Set<CLRegion> {
        locationManager.monitoredRegions
    }

    /// The maximum region size, in terms of a distance from a central point, that the framework can support.
    public var maximumRegionMonitoringDistance: CLLocationDistance {
        locationManager.maximumRegionMonitoringDistance
    }

    /// Indicates whether the app should receive location updates when suspended.
    /// Setting this to `true` requires setting `UIBackgroundModes` to `location` in `Info.plist`
    public var allowsBackgroundLocationUpdates: Bool {
        get { locationManager.allowsBackgroundLocationUpdates }
        set {
            locationManager.allowsBackgroundLocationUpdates = newValue
        }
    }

    /// Does this location manager use the location in the background?
    public var usesLocationInBackground: Bool {
        usage.requiresBackgroundLocation
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

    private var freshLocationTimers: [Timer] = []

    /// save last send state to avoid constant delegate calls
    private var lastDelegateFreshState: [ObjectIdentifier: Bool] = [:]

    /// Does the location manager have the required authorization level for `usage`?
    public static func hasRequiredAuthorizationLevel(forUsage usage: Set<LocationMonitoringUsage>) -> Bool {
        let authorizationStatus = CLLocationManager.authorizationStatus()
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

    /// Does the location manager have the required authorization level for `usage`?
    public static func hasRequiredAuthorizationLevel(forUsage usage: LocationMonitoringUsage) -> Bool {
        hasRequiredAuthorizationLevel(forUsage: Set([usage]))
    }

    public func getAuthorizationStatus(completion: @escaping (CLAuthorizationStatus) -> Void) {
        if let authorizationStatus {
            completion(authorizationStatus)
        } else {
            let id = UUID()
            let timer = Timer.scheduledTimer(withTimeInterval: timeoutTime, repeats: false) { [weak self] _ in
                guard let self else { return }
                if let callback = self.pendingAuthorizationStatusCallbacks[id] {
                    callback(.notDetermined)
                    self.pendingAuthorizationStatusCallbacks.removeValue(forKey: id)
                }
            }
            pendingAuthorizationStatusCallbacks[id] = completion
        }
    }

    /// The underlying location manager
    private(set) var locationManager: UBLocationManagerProtocol

    /// The last location update received from the system.
    public private(set) var lastLocation: CLLocation?

    /// The last heading update received from the system.
    public private(set) var lastHeading: CLHeading?

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
    ///   - usage: The desired usage, e.g. `[.location(background: false), .heading(background: true)]`
    ///   - canAskForPermission: Whether the location manager can ask for the required permission on its own behalf
    public func startLocationMonitoring(for usage: Set<LocationMonitoringUsage>, delegate: UBLocationManagerDelegate, canAskForPermission: Bool) {
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

    /// Start monitoring location service events (varies by `usage`)
    ///
    /// - Parameters:
    ///   - usage: The desired usage, e.g. `.location(background: false)`
    ///   - canAskForPermission: Whether the location manager can ask for the required permission on its own behalf
    public func startLocationMonitoring(for usage: LocationMonitoringUsage, delegate: UBLocationManagerDelegate, canAskForPermission: Bool) {
        startLocationMonitoring(for: Set([usage]), delegate: delegate, canAskForPermission: canAskForPermission)
    }

    /// Restart any monitoring that's used by a delegate.
    /// This method can be called as a safety measure to ensure location updates
    /// A good place to call this method is a location button in map app
    public func restartLocationMonitoring() {
        if usage.containsLocation {
            locationManager.startUpdatingLocation()
        }
        if usage.contains(.significantChange), locationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
        }
        if usage.contains(.visits) {
            locationManager.startMonitoringVisits()
        }
        if usage.containsHeading {
            locationManager.startUpdatingHeading()
        }
        if usage.containsRegions {
            for region in usage.regionsToMonitor {
                if !locationManager.monitoredRegions.contains(region) {
                    locationManager.startMonitoring(for: region)
                }
            }
        }
    }

    /// Stops monitoring location service events and removes the delegate
    public func stopLocationMonitoring(forDelegate delegate: UBLocationManagerDelegate) {
        let id = ObjectIdentifier(delegate)
        if let delegate = delegateWrappers.removeValue(forKey: id) {
            stopLocationMonitoring(delegate.usage)
        }

        self.startLocationMonitoringForAllDelegates()

        assert(!delegateWrappers.isEmpty || usage == [])
    }

    /// Stops monitoring all location service events
    private func stopLocationMonitoring(_ usage: Set<LocationMonitoringUsage>? = nil) {
        let usage = usage ?? self.usage

        timedOut = false
        locationTimer?.invalidate()
        locationTimer = nil

        if usage.containsLocation {
            locationManager.stopUpdatingLocation()
        }
        if usage.contains(.significantChange), locationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.stopMonitoringSignificantLocationChanges()
        }
        if usage.contains(.visits) {
            locationManager.stopMonitoringVisits()
        }
        if usage.containsHeading {
            locationManager.stopUpdatingHeading()
        }
        if usage.containsRegions {
            for region in usage.regionsToMonitor {
                locationManager.stopMonitoring(for: region)
            }
        }
    }

    /// Permission request to get state of location permission (varies by `usage`)
    ///
    /// - Parameters:
    ///   - usage: The desired usage.
    ///   - callback: Asynchronous callback with result.
    public func requestPermission(for usage: Set<LocationMonitoringUsage>, callback: @escaping ((LocationPermissionRequestResult) -> Void)) {
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
                    if minimumAuthorizationLevelRequired == .always, self.askedForAlwaysPermissionAtLeastOnce {
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

    /// Permission request to get state of location permission (varies by `usage`)
    ///
    /// - Parameters:
    ///   - usage: The desired usage.
    ///   - callback: Asynchronous callback with result.
    public func requestPermission(for usage: LocationMonitoringUsage, callback: @escaping ((LocationPermissionRequestResult) -> Void)) {
        requestPermission(for: Set([usage]), callback: callback)
    }

    /// :nodoc:
    private func startLocationMonitoringWithoutChecks(_ delegate: UBLocationManagerDelegate) {
        guard locationManager.locationServicesEnabled() else {
            let requiredAuthorizationLevel = usage.minimumAuthorizationLevelRequired
            delegate.locationManager(self, requiresPermission: requiredAuthorizationLevel)
            return
        }

        if usage.containsLocation {
            locationManager.startUpdatingLocation()
            startLocationTimer()
        }
        if usage.contains(.significantChange), locationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
        }
        if usage.contains(.visits) {
            locationManager.startMonitoringVisits()
        }
        if usage.containsHeading {
            locationManager.startUpdatingHeading()
        }
        if usage.containsRegions {
            for region in usage.regionsToMonitor {
                if !locationManager.monitoredRegions.contains(region) {
                    locationManager.startMonitoring(for: region)
                }
            }
        }
    }

    private func startLocationTimer() {
        locationTimer?.invalidate()
        locationTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] _ in
            guard let self = self, let location = self.locationManager.location, location.timestamp > Date(timeIntervalSinceNow: -Double(self.maximumLastLocationTimestampSeconds)) else { return }
            self.timedOut = true

            self.notifyDelegates(withLocations: [location])
        })
    }

    private func startLocationFreshTimers() {
        freshLocationTimers.forEach { $0.invalidate() }

        freshLocationTimers = delegates.compactMap { delegate in
            guard let time = delegate.locationManagerMaxFreshAge else { return nil }

            return Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { [weak self, weak delegate] _ in
                guard let self = self, let delegate = delegate else { return }

                let lastState = self.lastDelegateFreshState[ObjectIdentifier(delegate), default: true]
                if lastState != false {
                    delegate.locationManager(self, locationIsFresh: false)
                    self.lastDelegateFreshState[ObjectIdentifier(delegate)] = false
                }
            })
        }
    }

    private func startLocationMonitoringForAllDelegates() {
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
                locationManager.requestAlwaysAuthorization()
                self.askedForAlwaysPermissionAtLeastOnce = true
            case .whenInUse:
                locationManager.requestWhenInUseAuthorization()
        }
    }
}

extension UBLocationManager: CLLocationManagerDelegate {
    public func locationManager(_: CLLocationManager, didChangeAuthorization authorization: CLAuthorizationStatus) {
        authorizationStatus = authorization
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
        let results: [CLLocation] = locations.filter { location -> Bool in
            // A negative value indicates that the latitude and longitude are invalid
            location.horizontalAccuracy >= 0 &&
                // GPS  may return 0 to indicate no location
                location.coordinate.latitude != 0 && location.coordinate.longitude != 0
        }

        if !results.isEmpty {
            locationTimer?.invalidate()
            locationTimer = nil
        }

        notifyDelegates(withLocations: results)

        startLocationFreshTimers()
    }

    private func notifyDelegates(withLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else { return }
        self.lastLocation = lastLocation

        for delegate in delegates {
            let filteredLocations: [CLLocation]
            if let filteredAccuracy = delegate.locationManagerFilterAccuracy {
                let targetAccuracy = (filteredAccuracy > 0 ? filteredAccuracy : 10)
                filteredLocations = locations.filter { $0.horizontalAccuracy < targetAccuracy }
            } else {
                filteredLocations = locations
            }

            delegate.locationManager(self, didUpdateLocations: filteredLocations)
            if let maxAge = delegate.locationManagerMaxFreshAge {
                let fresh = -lastLocation.timestamp.timeIntervalSinceNow < maxAge
                let lastFresh = lastDelegateFreshState[ObjectIdentifier(delegate), default: true]
                if fresh != lastFresh {
                    delegate.locationManager(self, locationIsFresh: fresh)
                    lastDelegateFreshState[ObjectIdentifier(delegate)] = fresh
                }
            }
        }
    }

    public func locationManager(_: CLLocationManager, didVisit visit: CLVisit) {
        for delegate in delegates {
            delegate.locationManager(self, didVisit: visit)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        for delegate in delegates {
            delegate.locationManager(self, didEnterRegion: region)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        for delegate in delegates {
            delegate.locationManager(self, didExitRegion: region)
        }
    }

    public func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading
        for delegate in delegates {
            delegate.locationManager(self, didUpdateHeading: newHeading)
        }
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        // This might be some temporary error. Just report it but do not stop
        // monitoring as it could be some temporary error and we just have to
        // wait for the next event
        for delegate in delegates {
            delegate.locationManager(self, didFailWithError: error)
        }
    }
}

public extension UBLocationManager {
    /// An authorization level granted by the user which allows starting location services
    enum AuthorizationLevel: Int {
        /// User authorized the app to start location services while it is in use
        case whenInUse
        /// User authorized the app to start location services at any time
        case always
    }

    /// Defines the level of accuracy granted by the user.
    enum AccuracyLevel: Int {
        case reduced, full
    }

    /// Defines the usage for `UBLocationManager`. Can be a combination of the defined options.
    enum LocationMonitoringUsage: Equatable, Hashable {
        case foregroundLocation
        case backgroundLocation
        case foregroundHeading
        case backgroundHeading
        case significantChange
        case visits
        case regions(Set<CLRegion>)

        /// Monitors location
        public static func location(background: Bool) -> LocationMonitoringUsage {
            background ? .backgroundLocation : .foregroundLocation
        }

        /// Monitors heading
        public static func heading(background: Bool) -> LocationMonitoringUsage {
            background ? .backgroundHeading : .foregroundHeading
        }
    }
}

extension Set where Element == UBLocationManager.LocationMonitoringUsage {
    /// :nodoc:
    var requiresBackgroundLocation: Bool {
        contains(.backgroundLocation) || contains(.backgroundHeading)
    }

    /// :nodoc:
    var containsRegions: Bool {
        for element in self {
            if case .regions = element {
                return true
            }
        }
        return false
    }

    var regionsToMonitor: Set<CLRegion> {
        var regions = Set<CLRegion>()
        for element in self {
            if case let .regions(r) = element {
                regions.formUnion(r)
            }
        }
        return regions
    }

    /// :nodoc:
    var minimumAuthorizationLevelRequired: UBLocationManager.AuthorizationLevel {
        if contains(.significantChange) || contains(.visits) || containsRegions || requiresBackgroundLocation {
            return .always
        } else {
            return .whenInUse
        }
    }

    /// :nodoc:
    var containsLocation: Bool {
        contains(.foregroundLocation) || contains(.backgroundLocation)
    }

    /// :nodoc:
    var containsHeading: Bool {
        contains(.foregroundHeading) || contains(.backgroundHeading)
    }
}

private extension CLAccuracyAuthorization {
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
