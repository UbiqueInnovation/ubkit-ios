//
//  QRScannerError.swift
//  
//
//  Created by Matthias Felix on 11.02.22.
//

import Foundation

public enum QRScannerError: Error {
    case cameraPermissionDenied
    case cameraPermissionRestricted
    case captureSessionError(Error?)
}
