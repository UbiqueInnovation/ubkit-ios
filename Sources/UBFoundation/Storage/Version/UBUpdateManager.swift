//
//  UBUpdateMAnager.swift
//  
//
//  Created by Marco Zimmermann on 09.02.23.
//

import Foundation

public class UBAppUpdateManager {
    // MARK: - Shared Manager

    public static let shared = UBAppUpdateManager()

    // MARK: - Function to call at app start

    public func migrate(_ callback : ((UBAppUpdateState) -> Void)) {
        if let lastVersion = lastMigratedVersion {
            if lastVersion == currentVersion {
                callback(.sameVersion(version: currentVersion))
            } else {
                let type = lastVersion.updateType(to: currentVersion)
                callback(.update(fromVersion: lastVersion, toVersion: currentVersion, type: type))
            }
        } else {
            callback(.newInstallation(toVersion: currentVersion))
        }

        lastMigratedVersion = currentVersion
    }

    // MARK: - Possibility to migrate from other mechanism used

    public func overwriteLastVersion(versionString : String?) {
        lastMigratedVersion = AppVersion(versionString: versionString)
    }

    // MARK: - Current app version

    private var currentVersion : AppVersion {
        AppVersion(versionString: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
    }

    @UBUserDefault(key: "ubkit.ubupdatemanager.lastsavedversion.key", defaultValue: nil)
    private var lastMigratedVersion: AppVersion?
}

public struct AppVersion : UBCodable, Equatable {

    // MARK: - Init

    fileprivate init(versionString: String?) {
        var split = (versionString?.split(separator: ".") ?? []).map { Int(String($0)) }
        major = split.removeFirst() ?? 1
        minor = split.removeFirst() ?? 0
        patch = split.removeFirst() ?? 0
    }

    // MARK: - Version major.minor.patch (e.g. v3.1.4)

    let major: Int
    let minor: Int
    let patch: Int

    fileprivate func updateType(to toVersion: AppVersion) -> UBAppUpdateType {
        if(self.major > toVersion.major) { return .major }
        if(self.minor > toVersion.minor) { return .minor }
        return .patch
    }
}

public enum UBAppUpdateState {
    case newInstallation(toVersion: AppVersion)
    case sameVersion(version: AppVersion)
    case update(fromVersion: AppVersion, toVersion: AppVersion, type: UBAppUpdateType)
}

public enum UBAppUpdateType {
    case major
    case minor
    case patch
}
