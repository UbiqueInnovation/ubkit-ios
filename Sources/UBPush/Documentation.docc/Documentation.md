# UBPush

The push module is a wrapper to facilitate using Apple's push capabilities.
 

## Usage

Clients should customize the following components specific to the client application:

 - `pushRegistrationManager`, which handles registration of push tokens on our server
 - `additionalPushRegistrationManagers`, allows to handle several push configurations on our server
 - `pushHandler`, which handles incoming pushes

 The following methods need to be added to the AppDelegate:
```swift

 import UBFoundationPush

 @UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate, UBPushRegistrationAppDelegate {

     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) ->ol {
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

     func application(_: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler:scaping (UIBackgroundFetchResult) -> Void) {
         UBPushManager.shared.pushHandler.handleDidReceiveResponse(userInfo, fetchCompletionHandler: completionHandler)
     }
}
```


Example of subclassing UBPushHandler:

```swift
class SubclassedPushHandler: UBPushHandler {
    // MARK: - Notification Categories

    private let checkoutAction = UNNotificationAction(identifier: NotificationActionIdentifier.checkout.rawValue,
                                                      title: UBLocalized.booking_detail_dropin_check_out_button)
    private lazy var checkoutCategory = UNNotificationCategory(identifier: NotificationCategoryIdentifier.checkout.rawValue,
                                                               actions: [checkoutAction],
                                                               intentIdentifiers: [],
                                                               options: [])

    override var notificationCategories: Set<UNNotificationCategory> {
        return Set([checkoutCategory])
    }


    // MARK: - Push handling

    override func showInAppPushDetails(for notification: UBPushNotification) {
        handleNotification(notification)
    }

    override func showInAppPushAlert(withTitle title: String, proposedMessage message: String, notification: UBPushNotification, shouldPresentCompletionHandler: ((UNNotificationPresentationOptions) -> Void)? = nil) {
        shouldPresentCompletionHandler?([.banner, .sound])
        handleNotification(notification)
    }

    private func handleNotification(_ notification: UBPushNotification) {
       // Handle notification
    }
}
```

Clients can either create a pushRegistrationManager with a `registrationUrl`

```swift
     let registrationManager = UBPushRegistrationManager(registrationUrl: registrationUrl)
```

or subclass `UBPushRegistrationManager`, overriding `pushRegistrationRequest` if they require a custom registration request.


```swift
class PushRegistrationManager: UBPushRegistrationManager {
    override var pushRegistrationRequest: UBURLRequest? {
        // return URLRequest for push registration
    }
}

```
