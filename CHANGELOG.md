# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- UBLabel.attributedText respects attributes of label type 

### Changed


### Removed

### Fixed


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


