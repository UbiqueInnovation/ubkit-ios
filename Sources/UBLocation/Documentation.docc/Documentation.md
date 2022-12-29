# UBLocation


A convenience wrapper for `CLLocationManager` which facilitates obtaining the required authorization
for the desired usage (defined as a set of `UBLocationManager.LocationMonitoringUsage`)

## Usage

```swift

UBLocationManager.shared.requestPermission(for: .heading(background: false)) {_ in }

UBLocationManager.shared.startLocationMonitoring(for: [.location(background: false), .significantChange], delegate: self, canAskForPermission: true)
\\ or
UBLocationManager.shared.startLocationMonitoring(for: .regions(...), delegate: self, canAskForPermission: true)

UBLocationManager.shared.stopLocationMonitoring(forDelegate: self)

```

