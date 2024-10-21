//
//  MockLocationManagerDelegate.swift
//  UBFoundationLocation
//
//  Created by Zeno Koller on 29.04.20.
//  Copyright © 2020 Ubique Apps & Technology. All rights reserved.
//

import CoreLocation
import UBLocation

class MockLocationManagerDelegate: NSObject, UBLocationManagerDelegate {
    func locationManager(_: UBLocationManager, grantedPermission _: UBLocationManager.AuthorizationLevel, accuracy _: UBLocationManager.AccuracyLevel) {}

    func locationManager(_: UBLocationManager, requiresPermission _: UBLocationManager.AuthorizationLevel) {}

    func locationManager(_: UBLocationManager, didUpdateLocations _: [CLLocation]) {}

#if !os(visionOS)
    func locationManager(_: UBLocationManager, didUpdateHeading _: CLHeading) {}

    func locationManager(_: UBLocationManager, didVisit _: CLVisit) {}
#endif

    func locationManager(_: UBLocationManager, didFailWithError _: Error) {}

    var locationManagerFilterAccuracy: CLLocationAccuracy? { nil }
}
