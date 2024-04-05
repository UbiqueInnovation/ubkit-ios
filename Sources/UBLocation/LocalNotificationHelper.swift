//
//  LocalNotificationHelper.swift
//
//
//  Created by Matthias Felix on 11.07.23.
//

import UserNotifications

public enum LocalNotificationHelper {
    private static let notificationCenter: UNUserNotificationCenter = .current()

    public static func showDebugNotification(title: String, body: String) {
        let notification = UNMutableNotificationContent()
        notification.title = title
        notification.body = body
        notification.sound = .default

        notificationCenter.add(UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)), withCompletionHandler: nil)
    }
}
