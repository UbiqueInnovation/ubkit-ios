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

    func wantsUpdate(for usg: Set<UBLocationManager.LocationMonitoringUsage>?, isBackground: Bool) -> Bool {
        guard let usg else {
            return isBackground ? usage.requiresBackgroundUpdates : true
        }

        let intersection = usage.intersection(usg)
        
        if intersection.isEmpty {
            return false
        }

        if !isBackground {
            return true
        }

        return intersection.requiresBackgroundUpdates
    }
}
