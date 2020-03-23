# UBFoundationLocation Usage

A `UBLocationManager` facilitates asking for the required authorization level for the desired usage (location, significant updates, visits or heading). 
It can be instantiated with a single usage, which is of type `UBLocationManager.LocationMonitoringUsage`:
```swift
let locationManager = UBLocationManager(usage: .location) 
```
or a set of usages:
```swift
let locationManager = UBLocationManager(usage: [.location, .heading])  
```

The location manager forwards the updates to the client's `UBLocationManagerDelegate`, similar to the `CLLocationManagerDelegate`.

```swift

class MapViewController: CLLocationManagerDelegate {
    // ...

    init() {
        locationManager.delegate = self 
    }
    
    // ... implements delegate methods
}
```

The monitoring for the desired location services are started and stopped with 

```swift
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated: animated)
        
        // The location manager can ask for the required location permission,
        // if it has not been granted yet...
        locationManager.startLocationMonitoring(canAskForPermission: true)
        
        // ...or not, where it is assumed that the user has been asked to grant
        // location permissions at some other point in the application.
        locationManager.startLocationMonitoring(canAskForPermission: false)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated: animated)
        locationManager.stopLocationMonitoring()
    }
}
```