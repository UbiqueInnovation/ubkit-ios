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

    func locationManager(_ manager: UBLocationManager, grantedPermission permission: UBLocationManager.LocationMonitoringUsage.AuthorizationLevel) {}

    func locationManager(_ manager: UBLocationManager, requiresPermission permission: UBLocationManager.LocationMonitoringUsage.AuthorizationLevel) {}

    func locationManager(_ manager: UBLocationManager, didUpdateLocations locations: [CLLocation]) {}

    func locationManager(_ manager: UBLocationManager, didUpdateHeading newHeading: CLHeading) {}

    func locationManager(_ manager: UBLocationManager, didVisit visit: CLVisit) {}

    func locationManager(_ manager: UBLocationManager, didFailWithError error: Error) {}
}
