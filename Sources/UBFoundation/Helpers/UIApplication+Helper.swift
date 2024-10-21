//
//  UIApplication+Helper.swift
//  UBFoundation
//
//  Created by Marco Zimmermann on 12.05.23.
//

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

extension UIApplication {
    // MARK: - Public

    // if available provides best possible link to notification settings of app directly
    @objc public static let ub_appNotificationSettingsURL = URL(string: notificationSettingsURLString)

    // MARK: - Implementation

    private static let notificationSettingsURLString: String = {
        if #available(iOS 16, *) {
            return UIApplication.openNotificationSettingsURLString
        }

        if #available(iOS 15.4, *) {
            return UIApplicationOpenNotificationSettingsURLString
        }

        return UIApplication.openSettingsURLString
    }()
}
#endif
