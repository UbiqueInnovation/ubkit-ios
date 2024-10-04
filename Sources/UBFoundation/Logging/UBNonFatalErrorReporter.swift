//
//  UBNonFatalErrorReporter.swift
//
//
//  Created by Matthias Felix on 11.06.2024.
//

import Foundation

public actor UBNonFatalErrorReporter {
    public static let shared = UBNonFatalErrorReporter()

    private init() {}

    private var handler: ((Error) -> Void)?

    public func setHandler(_ handler: ((Error) -> Void)?) {
        self.handler = handler
    }

    nonisolated func report(_ error: Error) {
        Task {
            await _report(error)
        }
    }

    private func _report(_ error: Error) {
        handler?(error)
    }
}
