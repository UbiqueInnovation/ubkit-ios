//
//  UBLocationManagerDelegateWrapper.swift
//  
//  Created by Zeno Koller on 29.04.20.
//  Copyright © 2020 Ubique. All rights reserved.
//

import Foundation

class UBLocationManagerDelegateWrapper {

    let usage: UBLocationManager.LocationMonitoringUsage

    weak var delegate: UBLocationManagerDelegate?

    init(_ delegate: UBLocationManagerDelegate, usage: UBLocationManager.LocationMonitoringUsage) {
        self.delegate = delegate
        self.usage = usage
    }
}
