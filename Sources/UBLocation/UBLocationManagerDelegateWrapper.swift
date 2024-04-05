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
        if let usg {
            guard !usage.isDisjoint(with: usg) else { return false }
            let union = usage.union(usg)
            return isBackground ? union.requiresBackgroundUpdates : true
        } else {
            return isBackground ? usage.requiresBackgroundUpdates : true
        }
    }
}
