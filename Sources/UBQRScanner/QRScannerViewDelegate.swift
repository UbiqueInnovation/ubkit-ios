//
//  QRScannerViewDelegate.swift
//  
//
//  Created by Matthias Felix on 11.02.22.
//

import Foundation

public protocol QRScannerViewDelegate: AnyObject {
    func qrScanningDidFailWithError(_ error: QRScannerError)
    func qrScanningDidSucceedWithCode(_ code: String?)
    func qrScanningDidStop()
}
