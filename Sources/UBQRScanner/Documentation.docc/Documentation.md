# UBQRScanner

A view that provides functionalty related to the scanning of QR codes and other supported formats,
using the device's video camera. When started, the view displays the video camera feed. Events, like
the successful scanning of a code or specific errors are received via the `QRScannerViewDelegate` methods.
- Important: Apps using this view must provide a value for `NSCameraUsageDescription` in their `Info.plist`,
else the app will crash as soon as the `startScanning()` method is called.
