//
//  UBPushManager.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 23.03.20.
//

import UIKit
import UserNotifications
import UBFoundation

/// Handles requesting push permissions. Clients should customize the following components specific to the client application:
///
/// - `pushRegistrationManager`, which handles registration of push tokens on our server
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
///    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
///        UBPushManager.shared.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
///    }
///
///    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
///        UBPushManager.shared.didFailToRegisterForRemoteNotifications(with: error)
///    }
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
            if let token = UBPushLocalStorage.shared.pushToken {
                pushRegistrationManager.setPushToken(token)
            }
        }
    }

    /// Handles incoming pushes
    public var pushHandler = UBPushHandler()

    /// The push token for this device
    public var pushToken: String? {
        UBPushLocalStorage.shared.pushToken
    }

    /// The permission request callback of a pending permission requist, if any.
    private var permissionRequestCallback: PermissionRequestCallback?

    /// Counter to identify the latest push request
    private var latestPushRequest = 0

    // MARK: - Initialization

    /// :nodoc:
    private override init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Configuration

    public func didFinishLaunchingWithOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
                                              pushHandler: UBPushHandler,
                                              pushRegistrationManager: UBPushRegistrationManager) {
        self.pushHandler = pushHandler
        self.pushRegistrationManager = pushRegistrationManager
        self.pushRegistrationManager.sendPushRegistrationIfOutdated()
        self.pushHandler.handleLaunchOptions(launchOptions)
    }

    // MARK: - Push Permission Request Flow

    /// Requests push permissions
    ///
    /// - Parameters:
    ///     - includingCritical: Also requests permissions for critical alerts; requires iOS 12 and needs special authorization from Apple
    ///     - callback: The callback for handling the result of the request
    public func requestPushPermissions(includingCritical: Bool = false,
                                       callback: @escaping PermissionRequestCallback) {
        if let previousCallback = self.permissionRequestCallback {
            Self.logger.error("Tried to request push permissions while other request pending")
            previousCallback(.nonRecoverableFailure)
            permissionRequestCallback = nil
        }
        permissionRequestCallback = callback

        latestPushRequest += 1
        let currentPushRequest = latestPushRequest

        let options = makeAuthorizationOptions(includingCritical: includingCritical)
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

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// :nodoc:
    private func makeAuthorizationOptions(includingCritical: Bool) -> UNAuthorizationOptions {
        if #available(iOS 12.0, *) {
            return includingCritical ? [.alert, .badge, .sound, .criticalAlert] : [.alert, .badge, .sound]
        } else {
            assert(!includingCritical)
            return [.alert, .badge, .sound]
        }
    }

    /// Needs to be called inside `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
    public func didRegisterForRemoteNotificationsWithDeviceToken(_ token: Data) {
        let tokenString = token.hexString

        pushRegistrationManager.setPushToken(tokenString)

        if let callback = self.permissionRequestCallback {
            callback(.success)
            permissionRequestCallback = nil
        }
    }

    /// Needs to be called inside `application(_:didFailToRegisterForRemoteNotificationsWithError:)`
    public func didFailToRegisterForRemoteNotifications(with error: Error) {

        pushRegistrationManager.setPushToken(nil)

        if let callback = self.permissionRequestCallback {
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
}

// MARK: - Permission Request Result with Settings URL

private extension UBPushManager.PermissionRequestResult {
    /// :nodoc:
    static var failure: UBPushManager.PermissionRequestResult {
        if
            let settingsUrl = URL(string: UIApplication.openSettingsURLString),
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
