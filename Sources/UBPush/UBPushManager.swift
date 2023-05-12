//
//  UBPushManager.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 23.03.20.
//

import UBFoundation
import UIKit
import UserNotifications

/// Handles requesting push permissions. Clients should customize the following components specific to the client application:
///
/// - `pushRegistrationManager`, which handles registration of push tokens on our server
/// - `additionalPushRegistrationManagers`, allows to handle several push configurations on our server
/// - `pushHandler`, which handles incoming pushes
///
/// The following calls need to be added to the app delegate:
///
///     import UBFoundationPush
///
///     @UIApplicationMain
///     class AppDelegate: UIResponder, UIApplicationDelegate, UBPushRegistrationAppDelegate {
///
///         func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
///             let pushHandler = SubclassedPushHandler()
///             // Only use this initializer if using default registration API, otherwise
///             // also subclass UBPushRegistrationManager
///             let registrationManager = UBPushRegistrationManager(registrationURL: someUrl)
///             UBPushManager.shared.application(application,
///                                              didFinishLaunchingWithOptions: launchOptions,
///                                              pushHandler: pushHandler,
///                                              pushRegistrationManager: pushRegistrationManager)
///         }
///
///         func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
///               UBPushManager.shared.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
///         }
///
///         func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
///               UBPushManager.shared.didFailToRegisterForRemoteNotifications(with: error)
///         }
///
///         func application(_: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
///             UBPushManager.shared.pushHandler.handleDidReceiveResponse(userInfo, fetchCompletionHandler: completionHandler)
///         }
///

open class UBPushManager: NSObject {
    static let logger: UBLogger = UBPushLogging.frameworkLoggerFactory(category: "PushManager")

    /// Closure to handle the permission request result
    public typealias PermissionRequestCallback = (PermissionRequestResult) -> Void

    /// :nodoc:
    public enum PermissionRequestResult {
        /// Push permission was obtained successfully
        case success
        /// Push permission was not obtained, but the user can be prompted to access the settings
        case recoverableFailure(settingsURL: URL)
        /// Push permission was not obtained and the user cannot be prompted to access the settings
        case nonRecoverableFailure
    }

    /// The shared push manager which should be configured upon launch.
    public static let shared = UBPushManager()

    /// Handles registration of push tokens on our server
    public var pushRegistrationManager = UBPushRegistrationManager() {
        didSet {
            if let token = UBPushTokenStorage.shared.pushToken {
                pushRegistrationManager.setPushToken(token)
            }
        }
    }

    public var additionalPushRegistrationManagers: [UBPushRegistrationManager] = [] {
        didSet {
            if let token = UBPushTokenStorage.shared.pushToken {
                for additional in additionalPushRegistrationManagers {
                    additional.setPushToken(token)
                }
            }
        }
    }

    private struct UBPushTokenStorage {
        static var shared = UBPushTokenStorage()

        /// The push token obtained from Apple
        @UBUserDefault(key: "UBPushManager_Token", defaultValue: nil)
        var pushToken: String?
    }

    private var allPushRegistrationManagers: [UBPushRegistrationManager] {
        [pushRegistrationManager] + self.additionalPushRegistrationManagers
    }

    /// Handles incoming pushes
    public var pushHandler = UBPushHandler()

    /// The push token for this device
    public var pushToken: String? {
        UBPushTokenStorage.shared.pushToken
    }

    /// The permission request callback of a pending permission requist, if any.
    private var permissionRequestCallback: PermissionRequestCallback?

    /// Counter to identify the latest push request
    private var latestPushRequest = 0

    // MARK: - Initialization

    /// :nodoc:
    override private init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    // MARK: - App Delegate

    /// Needs to be called inside `applicationDidFinishLaunchingWithOptions(_:launchOptions:)`
    public func didFinishLaunchingWithOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
                                              pushHandler: UBPushHandler,
                                              pushRegistrationManager: UBPushRegistrationManager,
                                              additionalPushRegistrationManagers: [UBPushRegistrationManager] = []) {
        self.pushHandler = pushHandler
        self.pushRegistrationManager = pushRegistrationManager
        self.additionalPushRegistrationManagers = additionalPushRegistrationManagers

        for prm in self.allPushRegistrationManagers {
            prm.sendPushRegistrationIfOutdated()
        }

        self.pushHandler.handleLaunchOptions(launchOptions)

        // Request APNS token on startup
        registerForPushNotification()
    }

    /// Needs to be called upon `applicationDidBecomeActiveNotification`
    @objc
    private func applicationDidBecomeActive() {
        for aprm in self.allPushRegistrationManagers {
            aprm.sendPushRegistrationIfOutdated()
        }
    }

    // MARK: - Migration

    /// Update push token from a previous version directly
    public func migratePushToken(currentToken: String) {
        // set global token
        UBPushTokenStorage.shared.pushToken = currentToken

        // for all registration managers
        for prm in self.allPushRegistrationManagers {
            prm.setPushToken(currentToken)
        }
    }

    // MARK: - Push Permission Request Flow

    /// Requests APNS token (if .authorized)
    ///
    private func registerForPushNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                UNUserNotificationCenter.current().setNotificationCategories(self.pushHandler.notificationCategories)

                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    /// Requests push permissions
    ///
    /// - Parameters:
    ///     - includingCritical: Also requests permissions for critical alerts; requires iOS 12 and needs special authorization from Apple
    ///     - callback: The callback for handling the result of the request
    public func requestPushPermissions(includingCritical: Bool = false,
                                       includingNotificationSettings: Bool = false,
                                       callback: @escaping PermissionRequestCallback) {
        if let previousCallback = permissionRequestCallback {
            Self.logger.error("Tried to request push permissions while other request pending")
            previousCallback(.nonRecoverableFailure)
            permissionRequestCallback = nil
        }
        permissionRequestCallback = callback

        latestPushRequest += 1
        let currentPushRequest = latestPushRequest

        let options = makeAuthorizationOptions(includingCritical: includingCritical, includingNotificationSettings: includingNotificationSettings)
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, _ in

            guard granted else {
                DispatchQueue.main.async {
                    callback(.failure)
                    self.permissionRequestCallback = nil
                }
                return
            }

            // If registering for remote notifications was not handled by the system within a short period,
            // assume the permission request failed
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 15) { [weak self] in
                guard let self = self else { return }

                if let callback = self.permissionRequestCallback, currentPushRequest == self.latestPushRequest {
                    callback(.failure)
                    self.permissionRequestCallback = nil
                }
            }

            UNUserNotificationCenter.current().setNotificationCategories(self.pushHandler.notificationCategories)

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// :nodoc:
    private func makeAuthorizationOptions(includingCritical: Bool, includingNotificationSettings: Bool) -> UNAuthorizationOptions {
        var options : UNAuthorizationOptions = [.alert, .badge, .sound]

        if(includingCritical) {
            if #available(iOS 12.0, *) {
                options.insert(.criticalAlert)
            } else {
                assert(false)
            }
        }

        if(includingNotificationSettings) {
            if #available(iOS 12.0, *) {
                options.insert(.providesAppNotificationSettings)
            } else {
                assert(false)
            }
        }

        return options
    }

    /// Needs to be called inside `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
    public func didRegisterForRemoteNotificationsWithDeviceToken(_ token: Data) {
        let tokenString = token.hexString

        // set global token
        UBPushTokenStorage.shared.pushToken = tokenString

        // for all registration managers
        for prm in self.allPushRegistrationManagers {
            prm.setPushToken(tokenString)
        }

        if let callback = permissionRequestCallback {
            callback(.success)
            permissionRequestCallback = nil
        }
    }

    /// Needs to be called inside `application(_:didFailToRegisterForRemoteNotificationsWithError:)`
    public func didFailToRegisterForRemoteNotifications(with error: Error) {
        // set global token
        UBPushTokenStorage.shared.pushToken = nil

        // for all registration managers
        for prm in self.allPushRegistrationManagers {
            prm.setPushToken(nil)
        }

        if let callback = permissionRequestCallback {
            callback(.nonRecoverableFailure)
            permissionRequestCallback = nil
        }

        Self.logger.error("didFailToRegisterForRemoteNotificationsWithError: \(error.localizedDescription)")
    }

    /// Querys the current push permissions from the system
    public func queryPushPermissions(callback: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isEnabled = settings.alertSetting == .enabled
            DispatchQueue.main.async {
                callback(isEnabled)
            }
        }
    }

    // MARK: - Push Registration

    /// Invalidates the current push registration, forcing a new registration request
    @available(*, deprecated, renamed: "invalidateAndResendPushRegistration")
    public func invalidatePushRegistration() {
        for prm in self.allPushRegistrationManagers {
            prm.invalidate()
        }
    }

    /// Invalidates the current push registration, forcing a new registration request
    public func invalidateAndResendPushRegistration(completion: ((Error?) -> Void)? = nil) {
        for prm in self.allPushRegistrationManagers {
            prm.invalidate(completion: completion)
        }
    }
}

// MARK: - UNNotificationCenterDelegate

extension UBPushManager: UNUserNotificationCenterDelegate {
    /// :nodoc:
    public func userNotificationCenter(_: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        pushHandler.handleWillPresentNotification(notification, completionHandler: completionHandler)
    }

    /// :nodoc:
    public func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        pushHandler.handleDidReceiveResponse(response, completionHandler: completionHandler)
    }

    /// :nodoc:
    public func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        pushHandler.openInAppSettings(notification)
    }
}

// MARK: - Permission Request Result with Settings URL

private extension UBPushManager.PermissionRequestResult {
    /// :nodoc:
    static var failure: UBPushManager.PermissionRequestResult {
        if
            let settingsUrl = UIApplication.ub_appNotificationSettingsURL,
            UIApplication.shared.canOpenURL(settingsUrl) {
            return .recoverableFailure(settingsURL: settingsUrl)
        } else {
            return .nonRecoverableFailure
        }
    }
}

// MARK: - Hex Encoding

private extension Data {
    /// :nodoc:
    var hexString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}
