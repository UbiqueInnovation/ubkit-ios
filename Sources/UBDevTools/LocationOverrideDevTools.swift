import CoreLocation
import Foundation
import ObjectiveC

enum LocationOverrideDevTools: DevTool {
    nonisolated static let selectionKey = "ubkit.devtools.location.selection"
    nonisolated static let latitudeKey = "ubkit.devtools.location.latitude"
    nonisolated static let longitudeKey = "ubkit.devtools.location.longitude"
    nonisolated static let locationsLock = NSLock()
    nonisolated(unsafe) private static var appLocations: [(name: String, latitude: Double, longitude: Double)] = []

    nonisolated static var additionalLocations: [(name: String, latitude: Double, longitude: Double)] {
        locationsLock.lock()
        defer { locationsLock.unlock() }
        return appLocations
    }

    static func setCustomLocationOverrides(_ locations: [(name: String, latitude: Double, longitude: Double)]) {
        precondition(Set(locations.map { $0.name }).count == locations.count, "Location names must be unique")
        for location in locations {
            precondition(!location.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            precondition(location.latitude.isFinite && (-90...90).contains(location.latitude))
            precondition(location.longitude.isFinite && (-180...180).contains(location.longitude))
        }
        locationsLock.lock()
        appLocations = locations
        locationsLock.unlock()
        LocationOverrideIndicator.refresh()
    }

    nonisolated static func coordinate(latitude: String, longitude: String) -> CLLocationCoordinate2D? {
        guard let latitude = Double(latitude), let longitude = Double(longitude),
            latitude.isFinite, longitude.isFinite,
            (-90...90).contains(latitude), (-180...180).contains(longitude)
        else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    nonisolated static var location: CLLocation? {
        let defaults = UserDefaults.standard
        let coordinate: CLLocationCoordinate2D

        switch defaults.string(forKey: selectionKey) {
            case "ub-office":
                coordinate = CLLocationCoordinate2D(latitude: 47.375613, longitude: 8.543676)
            case "bern":
                coordinate = CLLocationCoordinate2D(latitude: 46.9480, longitude: 7.4474)
            case "lugano":
                coordinate = CLLocationCoordinate2D(latitude: 46.0101, longitude: 8.9600)
            case "custom":
                guard
                    let customCoordinate = Self.coordinate(
                        latitude: defaults.string(forKey: latitudeKey) ?? "",
                        longitude: defaults.string(forKey: longitudeKey) ?? ""
                    )
                else { return nil }
                coordinate = customCoordinate
            case let selection?:
                guard let name = selection.hasPrefix("app:") ? String(selection.dropFirst(4)) : nil,
                    let entry = additionalLocations.first(where: { $0.name == name })
                else { return nil }
                coordinate = CLLocationCoordinate2D(latitude: entry.latitude, longitude: entry.longitude)
            case nil:
                return nil
        }

        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    static func setup() {
        if UserDefaults.standard.string(forKey: selectionKey) == "zurich" {
            UserDefaults.standard.set("ub-office", forKey: selectionKey)
        }
        CLLocationManager.installLocationOverride()
        LocationOverrideIndicator.setup()
    }
}

private final class LocationOverrideDelegate: NSObject, CLLocationManagerDelegate {
    weak var delegate: CLLocationManagerDelegate?

    init(_ delegate: CLLocationManagerDelegate) {
        self.delegate = delegate
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)) {
            return delegate?.responds(to: aSelector) == true
        }
        return super.responds(to: aSelector) || delegate?.responds(to: aSelector) == true
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        delegate
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager?(manager, didUpdateLocations: LocationOverrideDevTools.location.map { [$0] } ?? locations)
    }
}

private extension CLLocationManager {
    @MainActor static var locationOverrideInstalled = false
    nonisolated(unsafe) static var locationOverrideDelegateKey: UInt8 = 0

    @MainActor static func installLocationOverride() {
        guard !locationOverrideInstalled else { return }

        swizzle(#selector(setter: CLLocationManager.delegate), with: #selector(override_setDelegate(_:)))
        swizzle(#selector(getter: CLLocationManager.location), with: #selector(getter: CLLocationManager.override_location))
        swizzle(#selector(CLLocationManager.requestLocation), with: #selector(override_requestLocation))
        swizzle(#selector(CLLocationManager.startUpdatingLocation), with: #selector(override_startUpdatingLocation))
        #if !os(visionOS)
            swizzle(#selector(CLLocationManager.startMonitoringSignificantLocationChanges), with: #selector(override_startMonitoringSignificantLocationChanges))
        #endif
        locationOverrideInstalled = true
    }

    @MainActor static func swizzle(_ original: Selector, with replacement: Selector) {
        guard let originalMethod = class_getInstanceMethod(self, original),
            let replacementMethod = class_getInstanceMethod(self, replacement)
        else { fatalError("CLLocationManager location override could not be installed") }
        method_exchangeImplementations(originalMethod, replacementMethod)
    }

    @objc dynamic func override_setDelegate(_ delegate: CLLocationManagerDelegate?) {
        if delegate is LocationOverrideDelegate {
            override_setDelegate(delegate)
            return
        }
        guard let delegate else {
            objc_setAssociatedObject(self, &Self.locationOverrideDelegateKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            override_setDelegate(nil)
            return
        }

        let proxy = LocationOverrideDelegate(delegate)
        objc_setAssociatedObject(self, &Self.locationOverrideDelegateKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        override_setDelegate(proxy)
    }

    @objc dynamic var override_location: CLLocation? {
        LocationOverrideDevTools.location ?? self.override_location
    }

    @objc dynamic func override_requestLocation() {
        guard LocationOverrideDevTools.location != nil else {
            override_requestLocation()
            return
        }
        perform(#selector(deliverOverrideLocation), with: nil, afterDelay: 0)
    }

    @objc dynamic func override_startUpdatingLocation() {
        override_startUpdatingLocation()
        guard LocationOverrideDevTools.location != nil else { return }
        perform(#selector(deliverOverrideLocation), with: nil, afterDelay: 0)
    }

    #if !os(visionOS)
        @objc dynamic func override_startMonitoringSignificantLocationChanges() {
            override_startMonitoringSignificantLocationChanges()
            guard LocationOverrideDevTools.location != nil else { return }
            perform(#selector(deliverOverrideLocation), with: nil, afterDelay: 0)
        }
    #endif

    @objc func deliverOverrideLocation() {
        guard let location = LocationOverrideDevTools.location else { return }
        delegate?.locationManager?(self, didUpdateLocations: [location])
    }
}
