//
//  QRScannerView.swift
//
//
//  Created by Matthias Felix on 11.02.22.
//

import AVFoundation
import Foundation
import UIKit

/// A view that provides functionalty related to the scanning of QR codes and other supported formats,
/// using the device's video camera. When started, the view displays the video camera feed. Events, like
/// the successful scanning of a code or specific errors are received via the `QRScannerViewDelegate` methods.
/// - Important: Apps using this view must provide a value for `NSCameraUsageDescription` in their `Info.plist`,
/// else the app will crash as soon as the `startScanning()` method is called.
public class QRScannerView: UIView {
    /// The delegate that should receive events like successfully scanned codes or errors
    public weak var delegate: QRScannerViewDelegate?

    private lazy var videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video)

    /// capture session which allows us to start and stop scanning.
    private var captureSession: AVCaptureSession?

    public private(set) var isTorchOn = false

    private var lastIsRunning: Bool?
    private var lastIsTorchOn: Bool?

    /// When this is set to true, the capture session keeps running but no output is processed.
    /// One difference to stopping the scanning completely is that the torch can still be kept on while paused.
    private var isScanningPaused = true

    private let metadataObjectTypes: [AVMetadataObject.ObjectType]

    public init(delegate: QRScannerViewDelegate, metadataObjectTypes: [AVMetadataObject.ObjectType] = [.qr, .ean8, .ean13, .pdf417, .aztec]) {
        self.metadataObjectTypes = metadataObjectTypes

        super.init(frame: .zero)

        self.delegate = delegate
        clipsToBounds = true

        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }
            self.lastIsRunning = self.isRunning
            self.lastIsTorchOn = self.isTorchOn
            self.stopScanning()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }
            if let lastIsRunning = self.lastIsRunning, lastIsRunning == true {
                self.startScanning()
                if let lastIsTorchOn = self.lastIsTorchOn, lastIsTorchOn == true {
                    self.setTorch(on: true)
                }
            }
            self.lastIsRunning = nil
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: overriding the layerClass to return `AVCaptureVideoPreviewLayer`.

    override public class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    override public var layer: AVCaptureVideoPreviewLayer {
        super.layer as! AVCaptureVideoPreviewLayer
    }

    /// Whether the capture session is currently running
    public var isRunning: Bool {
        captureSession?.isRunning ?? false
    }

    /// Whether the device has a torch that can be enabled
    public var canEnableTorch: Bool {
        guard let camera = videoCaptureDevice else { return false }
        return camera.hasTorch && camera.isTorchAvailable
    }

    /// Start scanning, requesting the camera permission if needed
    public func startScanning() {
        isScanningPaused = false
        setupCaptureSessionIfNeeded()

        if let c = captureSession, !c.isRunning {
            c.startRunning()
        }
    }

    /// Turn the torch on or off
    public func setTorch(on: Bool) {
        guard let camera = videoCaptureDevice, canEnableTorch else { return }

        isTorchOn = on

        do {
            try camera.setTorch(on: isTorchOn)
        } catch {
            delegate?.qrScanningDidFailWithError(.torchError(error))
        }
    }

    /// Pauses the scanning, meaning that no input will be processed, but the
    /// capture session will continue to run
    public func pauseScanning() {
        isScanningPaused = true
    }

    /// Completely stops the capture session, by default also turning off the torch
    public func stopScanning(alsoTurnOffTorch: Bool = true) {
        isScanningPaused = true
        captureSession?.stopRunning()
        delegate?.qrScanningDidStop()

        if alsoTurnOffTorch {
            setTorch(on: false)
        }
    }

    // MARK: - Private helper methods

    /// Does the initial setup for captureSession
    private func setupCaptureSessionIfNeeded() {
        // check if user didn't deny camera usage to show error
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .restricted:
            scanningDidFail(error: .cameraPermissionRestricted)
        case .denied:
            scanningDidFail(error: .cameraPermissionDenied)
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
            scanningDidFail(error: .captureSessionError(error))
            return
        }

        guard let captureSession = captureSession, captureSession.canAddInput(videoInput) else {
            scanningDidFail(error: .captureSessionError(nil))
            return
        }
        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()

        guard captureSession.canAddOutput(metadataOutput) else {
            scanningDidFail(error: .captureSessionError(nil))
            return
        }
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = metadataObjectTypes

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
