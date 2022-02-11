//
//  QRScannerViewDelegate.swift
//
//
//  Created by Matthias Felix on 11.02.22.
//

import Foundation

/// Protocol for a delegate that receives events from the `QRScannerView`,
/// like successfully scanned codes or errors
public protocol QRScannerViewDelegate: AnyObject {
    func qrScanningDidFailWithError(_ error: QRScannerError)
    func qrScanningDidSucceedWithCode(_ code: String?)
    func qrScanningDidStop()
}
