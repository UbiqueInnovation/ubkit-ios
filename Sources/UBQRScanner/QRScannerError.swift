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
             return true
         case (.cameraPermissionRestricted, .cameraPermissionRestricted):
             return true
         case (.captureSessionError(let lhsError), .captureSessionError(let rhsError)):
             return lhsError?.localizedDescription == rhsError?.localizedDescription
         case (.torchError(let lhsError), .torchError(let rhsError)):
             return lhsError?.localizedDescription == rhsError?.localizedDescription
         default:
             return false
         }
     }
}
