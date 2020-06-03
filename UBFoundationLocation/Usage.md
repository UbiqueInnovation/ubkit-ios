# UBFoundationLocation Usage

A `UBLocationManager` facilitates asking for the required authorization level for the desired usage (location, significant updates, visits or heading). The location manager forwards the updates to the client's `UBLocationManagerDelegate`, similar to the `CLLocationManagerDelegate`.

```swift

class MapViewController: UBLocationManagerDelegate {
    
    // The location manager is a singleton, because multiple location manager instance
    // might interfere (shared state of GPS hardware)
    var locationManager = UBLocationManager.shared
    
    // ... implements delegate methods
}
```

The monitoring for the desired location services are started and stopped with 

```swift
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated: animated)
        
        // The location manager can ask for the required location permission,
        // if it has not been granted yet...
        let usage = [.location, .heading]
        locationManager.startLocationMonitoring(for: usage, delegate: self, canAskForPermission: true)
        
        // ...or not, where it is assumed that the user has been asked to grant
        // location permissions at some other point in the application.
        locationManager.startLocationMonitoring(for: usage, delegate: self, canAskForPermission: false)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated: animated)
        locationManager.stopLocationMonitoring(forDelegate: self)
    }
}
```
