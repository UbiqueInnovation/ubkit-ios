# UBFoundation
The UBFoundation framework provides a set of useful tools and helpers to make building apps faster and safer.

## Requirments
- iOS 11.0+ / Mac OS X 10.12+ / tvOS 12.0+ / watchOS 5.0+
- Xcode 10.0+
- Swift 4.2+

## Installation
Use Swift Package Manager

## Contribution
If you want to contribute to the framework, please check the contribution guide.

## Documentation
The framework is fully documented and easy to navigate on your own. You can consult the [online documentation](https://ubique.ch/ubFoundation/documentation). Or build it yourself by checking out the project and running the fastlane command `fastlane documentation`.
You can aslo find plenty of guides under the Documentation folder in the project.

# UBLocation

A `UBLocationManager` facilitates asking for the required authorization level for the desired usage (location, significant updates, visits, heading or region monitoring). The location manager forwards the updates to the client's `UBLocationManagerDelegate`, similar to the `CLLocationManagerDelegate`.

## Usage

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

# UBPush
Handles requesting push permissions and sending the registration to the backend.

## Usage
To use push notifications, the library `UBFoundationPush` needs to be imported.

`UBPushManager` handles requesting push permissions. Clients should customize the following components specific to the client application:

- `pushRegistrationManager`, which handles registration of push tokens on our server
- `pushHandler`, which handles incoming pushes

The following calls need to be added to the app delegate: 

```swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UBPushRegistrationAppDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let pushHandler = SubclassedPushHandler()
        // Only use this initializer if using default registration API, otherwise
        // also subclass UBPushRegistrationManager
        let registrationManager = UBPushRegistrationManager(registrationURL: someUrl)
        UBPushManager.shared.application(application,
                                         didFinishLaunchingWithOptions: launchOptions,
                                         pushHandler: pushHandler,
                                         pushRegistrationManager: pushRegistrationManager)
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UBPushManager.shared.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UBPushManager.shared.didFailToRegisterForRemoteNotifications(with: error)
    }
```

The `UBPushHandler` should be subclassed to implement application-specific behaviour for responding to push notifications while the app is running (in `showInAppPushAlert(withTitle:proposedMessage:notification:)`) and after the app is started when the user responded to a push (in  `showInAppPushDetails(for:)`).

The `UBPushRegistrationManager` can either be created with a `registrationUrl`":

```swift
let registrationManager = UBPushRegistrationManager(registrationUrl: registrationUrl)
```
or subclassed, if a custom `pushRegistrationRequest` is needed.

# License

Copyright (c) 2019-present Ubique Innovation AG

