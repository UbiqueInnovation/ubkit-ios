//
//  QRScannerViewDelegate.swift
//
//
//  Created by Matthias Felix on 11.02.22.
//

import Foundation

/// Protocol for a delegate that receives events from the `QRScannerView`,
/// like successfully scanned codes or errors
@MainActor
public protocol QRScannerViewDelegate: AnyObject {
    func qrScanningDidFailWithError(_ error: QRScannerError)
    // if true is returned no more codes will be passed to this delegate from the current frame
    func qrScanningDidSucceedWithCode(_ code: String?) -> Bool
    func qrScanningDidStop()
}
