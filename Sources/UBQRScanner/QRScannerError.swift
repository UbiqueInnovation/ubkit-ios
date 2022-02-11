//
//  QRScannerError.swift
//  
//
//  Created by Matthias Felix on 11.02.22.
//

import Foundation

/// Collection of errors the `QRScannerView` methods can return
public enum QRScannerError: Error {
    case cameraPermissionDenied
    case cameraPermissionRestricted
    case captureSessionError(Error?)
    case torchError(Error?)
}
