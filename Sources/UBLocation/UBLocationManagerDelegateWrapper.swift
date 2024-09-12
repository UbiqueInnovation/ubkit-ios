//
//  UBLocationManagerDelegateWrapper.swift
//
//  Created by Zeno Koller on 29.04.20.
//  Copyright © 2020 Ubique. All rights reserved.
//

import Foundation

class UBLocationManagerDelegateWrapper {
    let usage: Set<UBLocationManager.LocationMonitoringUsage>

    weak var delegate: UBLocationManagerDelegate?

    init(_ delegate: UBLocationManagerDelegate, usage: Set<UBLocationManager.LocationMonitoringUsage>) {
        self.delegate = delegate
        self.usage = usage
    }

    func wantsUpdate(for usg: Set<UBLocationManager.LocationMonitoringUsage>?, isBackground: Bool, allowsBackgroundLocationUpdates: Bool) -> Bool {
        // First, determine which usage we are checking against:
        // If a usage is given, we check whether we want an update for a specific usage set
        // If no usage is given, we just answer whether we want updates at the moment, given our usage set and app state (background or foreground)
        let usageToCheck = if let usg {
            usage.intersection(usg)
        } else {
            usage
        }

        // If the usage set is empty, we are not interested in this update, regardless of app state
        if usageToCheck.isEmpty {
            return false
        }

        // If the app is in the background, we only want an update if our usage
        // requires background updates or if 'allowsBackgroundLocationUpdates' is set to true,
        // in which case we can reveive updates even without background permissions.
        // If we're in the foreground, we always want the update.
        return isBackground ? usageToCheck.requiresBackgroundUpdates || allowsBackgroundLocationUpdates : true
    }
}
