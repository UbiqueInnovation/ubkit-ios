//
//  Networking+Error.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 20.03.19.
//

import Foundation

public enum NetworkingError: Error {
    case couldNotCreateBody(message: String?)
}
