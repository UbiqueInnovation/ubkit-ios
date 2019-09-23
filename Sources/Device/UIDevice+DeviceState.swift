//
//  UIDevice+DeviceState.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

/// Helpers for UIDevice
extension UIDevice
{
    /// Checks if current device is a tablet (iPad etc.)
    public static func ub_deviceIsTablet() -> Bool
    {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Checks if current device is a tablet (iPhone etc.)
    public static func ub_deviceIsPhone() -> Bool
    {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    /// Checks if current device is used in portrait mode
    public static func ub_isPortrait() -> Bool
    {
        let orientation = UIDevice.current.orientation
        return orientation == .portrait || orientation == .portraitUpsideDown
    }

    /// Checks if current device is used in landscape mode
    public static func ub_isLandscape() -> Bool
    {
        let orientation = UIDevice.current.orientation
        return orientation == .landscapeRight || orientation == .landscapeLeft
    }
}
