//
//  UBLocationManagerDelegateWrapper.swift
//
//  Created by Zeno Koller on 29.04.20.
//  Copyright © 2020 Ubique. All rights reserved.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

class UBLocationManagerDelegateWrapper {
    let usage: Set<UBLocationManager.LocationMonitoringUsage>

    weak var delegate: UBLocationManagerDelegate?

    init(_ delegate: UBLocationManagerDelegate, usage: Set<UBLocationManager.LocationMonitoringUsage>) {
        self.delegate = delegate
        self.usage = usage
    }
}
#endif
