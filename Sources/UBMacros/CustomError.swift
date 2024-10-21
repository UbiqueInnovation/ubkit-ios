//
//  CustomError.swift
//  UBKit
//
//  Created by Nicolas Märki on 12.09.2024.
//

import Foundation

enum CustomError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
            case let .message(text):
                text
        }
    }
}
