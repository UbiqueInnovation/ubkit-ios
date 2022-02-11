//
//  QRScannerView.swift
//  
//
//  Created by Matthias Felix on 11.02.22.
//

import Foundation
import UIKit
import AVFoundation

public class QRScannerView: UIView {
    public weak var delegate: QRScannerViewDelegate?

    private lazy var videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video)

    /// capture session which allows us to start and stop scanning.
    private var captureSession: AVCaptureSession?

    private var isTorchOn = false

    /// When this is set to true, the capture session keeps running but no output is processed.
    /// One difference to stopping the scanning completely is that the torch can still be kept on while paused.
    private var isScanningPaused = true
    
    private let metadataObjectTypes: [AVMetadataObject.ObjectType]

    public init(delegate: QRScannerViewDelegate, metadataObjectTypes: [AVMetadataObject.ObjectType] = [.qr, .ean8, .ean13, .pdf417, .aztec]) {
        self.metadataObjectTypes = metadataObjectTypes
        
        super.init(frame: .zero)
        
        self.delegate = delegate
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: overriding the layerClass to return `AVCaptureVideoPreviewLayer`.

    override public class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override public var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }
}

extension QRScannerView {
    public var isRunning: Bool {
        return captureSession?.isRunning ?? false
    }

    public var canEnableTorch: Bool {
        guard let camera = videoCaptureDevice else { return false }
        return camera.hasTorch && camera.isTorchAvailable
    }

    public func startScanning() {
        isScanningPaused = false
        setupCaptureSessionIfNeeded()

        if let c = captureSession, !c.isRunning {
            c.startRunning()
        }
    }

    public func setTorch(on: Bool) {
        guard let camera = videoCaptureDevice, canEnableTorch else { return }

        isTorchOn = on
        try? camera.setTorch(on: isTorchOn)
    }

    public func pauseScanning() {
        isScanningPaused = true
    }

    public func stopScanning() {
        isScanningPaused = true
        captureSession?.stopRunning()
        delegate?.qrScanningDidStop()

        setTorch(on: false)
    }

    /// Does the initial setup for captureSession
    private func setupCaptureSessionIfNeeded() {
        // check if user didn't deny camera usage to show error
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .restricted:
            scanningDidFail(error: .permissionRestricted)
        case .denied:
            scanningDidFail(error: .permissionDenied)
        default:
            if captureSession == nil {
                captureSession = AVCaptureSession()
                startCapture()
            }
        }
    }

    private func startCapture() {
        guard let videoCaptureDevice = videoCaptureDevice else {
            return
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            scanningDidFail(error: .internal(error))
            return
        }

        if captureSession?.canAddInput(videoInput) ?? false {
            captureSession?.addInput(videoInput)
        } else {
            scanningDidFail(error: .internal(nil))
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession?.canAddOutput(metadataOutput) ?? false {
            captureSession?.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = metadataObjectTypes
        } else {
            scanningDidFail(error: .internal(nil))
            return
        }

        layer.session = captureSession
        layer.videoGravity = .resizeAspectFill
    }

    private func scanningDidFail(error: QRScannerError) {
        delegate?.qrScanningDidFailWithError(error)
        isScanningPaused = true
        captureSession = nil
    }

    private func found(code: String) {
        delegate?.qrScanningDidSucceedWithCode(code)
    }
}

extension QRScannerView: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        guard !isScanningPaused else { return } // Don't process any input if scanning is paused

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            found(code: stringValue)
        }
    }
}

private extension AVCaptureDevice {
    func setTorch(on: Bool) throws {
        try lockForConfiguration()
        if on {
            try setTorchModeOn(level: 1)
        } else {
            torchMode = .off
        }
        unlockForConfiguration()
    }
}
