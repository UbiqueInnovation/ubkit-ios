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

extension QRScannerError: Equatable {
    public static func == (lhs: QRScannerError, rhs: QRScannerError) -> Bool {
        switch (lhs, rhs) {
            case (.cameraPermissionDenied, .cameraPermissionDenied):
                true
            case (.cameraPermissionRestricted, .cameraPermissionRestricted):
                true
            case let (.captureSessionError(lhsError), .captureSessionError(rhsError)):
                lhsError?.localizedDescription == rhsError?.localizedDescription
            case let (.torchError(lhsError), .torchError(rhsError)):
                lhsError?.localizedDescription == rhsError?.localizedDescription
            default:
                false
        }
    }
}
