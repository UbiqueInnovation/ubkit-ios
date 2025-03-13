//
//  UBPushHandler.swift
//  UBFoundation iOS
//
//  Created by Zeno Koller on 23.03.20.
//

import Foundation
import UBFoundation
import UIKit
import UserNotifications

/// Handles incoming push notifications. Clients should subclass `UBPushHandler` and set it in `UBPushManager` as
///
///     UBPushManager.shared.pushHandler = SubclassedPushHanlder()
///
/// to implement app-specific behaviour.
@MainActor
open class UBPushHandler: NSObject {
    /// Date of last push message. Override to modify app state after every push (e.g. wipe cache)
    public var lastPushed: Date? {
        get { storedLastPushed }
        set { storedLastPushed = newValue }
    }

    @UBUserDefault(key: "UBPushHandler_LastPushed", defaultValue: nil)
    private var storedLastPushed: Date?

    // MARK: - Initialization

    override public init() {
        super.init()
    }

    // MARK: - Default Implementations

    /// If `false`, a notification is presented only once per identifier.
    open var shouldPresentNotificationsAgain: Bool {
        true
    }

    /// Categories to register
    open var notificationCategories: Set<UNNotificationCategory> {
        Set()
    }

    /// Overrride to show an application-specific alert/popup in response to a push
    /// arriving while the application is running.
    open func showInAppPushAlert(withTitle _: String, proposedMessage _: String, notification _: UBPushNotification, shouldPresentCompletionHandler: ((UNNotificationPresentationOptions) -> Void)? = nil) {
        // Show notification banner also when app is already in foreground
        shouldPresentCompletionHandler?([.banner, .sound])
    }

    /// Override to present detail view after app is started when user responded to a push.
    /// Manually call this method after showInAppPushAlert(withTitle:proposedMessage:userInfo:) if required
    open func showInAppPushDetails(for _: UBPushNotification) {
        UBPushManager.logger.error("Subclasses of UBPushHandler should override UBPushHandler.showInAppPushAlert(withTitle:proposedMessage:notification:)")
    }

    /// Override to update local data (e.g. current warnings) after every remote notification. It's the clients responsibility to call the fetchCompletionHandler appropriately, if set
    open func updateLocalData(withSilent _: Bool, remoteNotification _: UBPushNotification, fetchCompletionHandler _: ((UIBackgroundFetchResult) -> Void)?) {
        UBPushManager.logger.error("Subclasses of UBPushHandler should override updateLocalData(withSilent:remoteNotification:)")
    }

    open func openInAppSettings(_ notification: UNNotification?) {
        // default empty
    }

    // MARK: - Handlers

    /// Handles notifications for the app to process upon launch. Resets the application icon badge number after user interaction.
    public func handleLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let userInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            lastPushed = Date()

            showInAppPushDetails(for: UBPushNotification(userInfo))
        }

        // Only reset badge number if user started the app by tapping on the app icon
        // or tapping on a notification (but not when started in background because of
        // a location change or some other event).
        if launchOptions == nil || launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] != nil || launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] != nil {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    /// Handles a notification that arrived while the app was running in the foreground.
    public func handleWillPresentNotification(_ notification: UNNotification, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let ubNotification = UBPushNotification(
            notification.request.content.userInfo,
            notificationRequestIdentifier: notification.request.identifier)
        // Let app decide (by overriding) whether and how to show a banner or not
        didReceive(ubNotification, whileActive: true, shouldPresentCompletionHandler: completionHandler)
    }

    /// Handles the user's response to an incoming notification.
    public func handleDidReceiveResponse(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        let ubNotification = UBPushNotification(
            response.notification.request.content.userInfo,
            notificationRequestIdentifier: response.notification.request.identifier,
            responseActionIdentifier: response.actionIdentifier)
        didReceive(ubNotification, whileActive: false)
        completionHandler()
    }

    /// Handles e.g. silent pushes that arrive in legacy method `AppDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`
    /// From Apple documentation:
    ///     As soon as you finish processing the notification, you must call the block in the handler parameter or your app will be terminated.
    public func handleDidReceiveResponse(_ userInfo: [AnyHashable: Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let ubNotification = UBPushNotification(userInfo)
        didReceive(ubNotification, whileActive: UIApplication.shared.applicationState == .active, fetchCompletionHandler: fetchCompletionHandler)
    }

    // MARK: - Helpers

    private func didReceive(_ notification: UBPushNotification, whileActive isActive: Bool, fetchCompletionHandler: ((UIBackgroundFetchResult) -> Void)? = nil, shouldPresentCompletionHandler: ((UNNotificationPresentationOptions) -> Void)? = nil) {
        lastPushed = Date()

        if !notification.isSilentPush {
            updateLocalData(withSilent: false, remoteNotification: notification, fetchCompletionHandler: fetchCompletionHandler)
            showNonSilent(notification, isActive: isActive, shouldPresentCompletionHandler: shouldPresentCompletionHandler)
        } else {
            updateLocalData(withSilent: true, remoteNotification: notification, fetchCompletionHandler: fetchCompletionHandler)
        }
    }

    private func showNonSilent(_ notification: UBPushNotification, isActive: Bool, shouldPresentCompletionHandler: ((UNNotificationPresentationOptions) -> Void)? = nil) {
        // Non-silent push while active
        // Show alert
        if isActive {
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "App Name Missing"

            let message: String =
                switch (notification.userInfo["aps"] as? [String: Any])?["alert"] {
                    case let stringAlert as String:
                        stringAlert
                    case let dictAlert as [String: Any]:
                        (dictAlert["body"] as? String) ?? ""
                    default:
                        ""
                }

            showInAppPushAlert(withTitle: appName, proposedMessage: message, notification: notification, shouldPresentCompletionHandler: shouldPresentCompletionHandler)
        }
        // Non-silent push while running in background
        // App will be launched because user selected "show more"
        // Show detail VC
        else {
            // For now, use delay to make sure app is ready.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
                self?.showInAppPushDetails(for: notification)
            }
        }
    }
}

/// A convenience wrapper for the notification received via a push message.
public struct UBPushNotification {
    public let userInfo: [AnyHashable: Any]
    public let notificationRequestIdentifier: String?
    public let responseActionIdentifier: String?

    public var isSilentPush: Bool {
        guard let aps = userInfo["aps"] as? [String: Any] else {
            return false
        }

        return aps["alert"] == nil && aps["sound"] == nil && aps["badge"] == nil && (aps["content-available"] as? Int) == 1
    }

    public init(_ userInfo: [AnyHashable: Any], notificationRequestIdentifier: String? = nil, responseActionIdentifier: String? = nil) {
        self.userInfo = userInfo
        self.notificationRequestIdentifier = notificationRequestIdentifier
        self.responseActionIdentifier = responseActionIdentifier
    }

    /// Tries to convert `userInfo` to a `Decodable` type `T`
    /// Example:
    ///
    ///     guard let payload: MyPayload = notification.payload() else {
    ///         return
    ///
    /// `MyPayload` should look as follows:
    ///
    ///     struct MyPayload: Decodable {
    ///         let aps: APS?
    ///
    ///         // Add properties here you need
    ///
    ///         struct APS: Decodable {
    ///             let sound: String?
    ///             let alert: Alert?
    ///         }
    ///
    ///         struct Alert: Decodable {
    ///             let body: String?
    ///             let title: String?
    ///         }
    ///     }
    ///
    public func payload<T: Decodable>() -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}
