# UBFoundationPush Usage

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

