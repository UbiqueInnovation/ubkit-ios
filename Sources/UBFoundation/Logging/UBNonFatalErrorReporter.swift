//
//  UBNonFatalErrorReporter.swift
//
//
//  Created by Matthias Felix on 11.06.2024.
//

import Foundation

public enum UBNonFatalErrorReporter {
    public static var handler: ((Error) -> Void)?

    static func report(_ error: Error) {
        handler?(error)
    }
}
