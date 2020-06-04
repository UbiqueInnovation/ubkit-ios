//
//  MockLocationManagerDelegate.swift
//  UBFoundationLocation
//
//  Created by Zeno Koller on 29.04.20.
//  Copyright © 2020 Ubique Apps & Technology. All rights reserved.
//

import CoreLocation
import UBFoundationLocation

class MockLocationManagerDelegate: NSObject, UBLocationManagerDelegate {
    func locationManager(_: UBLocationManager, grantedPermission _: UBLocationManager.LocationMonitoringUsage.AuthorizationLevel) {}

    func locationManager(_: UBLocationManager, requiresPermission _: UBLocationManager.LocationMonitoringUsage.AuthorizationLevel) {}

    func locationManager(_: UBLocationManager, didUpdateLocations _: [CLLocation]) {}

    func locationManager(_: UBLocationManager, didUpdateHeading _: CLHeading) {}

    func locationManager(_: UBLocationManager, didVisit _: CLVisit) {}

    func locationManager(_: UBLocationManager, didFailWithError _: Error) {}
}
