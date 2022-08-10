# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

### Changed

### Removed

### Fixed
- The QRScannerView now evaluates all QR-codes not only the first one found. Therefore the qrScanningDidSucceedWithCode has to return a bool wether this QR-Code was usable or not.

## 1.2.0
### Added
- UBUserDefaults 2.0 (support for Codable arrays, removal of UBOptionalUserDefault)
- Image tinting `ub_withColor`
- Added a new UI element: `UIStackView` in a `UIScrollView` named `UIStackScrollView`
- UBLocationManager restartLocationMonitoring
- UBUserDefaults support for dictionaries with string keys
- Added `locationManagerMaxFreshAge` and `locationManager(, locationIsFresh:)` to get notified if no location updates happend for too long

### Changed
- Push notification handeling is now relying on the system UI view and not a custom UIAlertView

### Fixed
- Multi-Push Registration

## 1.1.1
### Added
- UBLabel.attributedText respects attributes of label type 

## 1.1
### Added
- UBLabel, UBLabelType
- PushManager
- LocationManager
- Many other improvements

### Changed
- Disabled automatic pause on location manager
- Moved SwiftUI into own 
- Clean network errors

### Fixed
- Allowed missing transitions of networking state
- Fix certificate pinning
- Fixed tests
- Update cache headers on 304 response


## 1.0
### Added
- Localization Module
- Logging Module
- Networking Module: Request, Response, Task, Modifiers, Recovery
- Networking Security: Server Trust and Redirections
- Data Task status tracker
- UIColor from HEX
- Keyboard Layout Guide
- Cron Jobs
- Location Services: Convenience wrapper for authorization 
- UserDefaults Property Wrapper

### Changed
- Return cached metrics


