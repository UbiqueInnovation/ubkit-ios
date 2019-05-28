//
//  CacheControl.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 04.04.19.
//

import Foundation

public typealias UBCacheResponseDirectives = [UBCacheResponseDirective]

public struct UBCacheResponseDirective: Hashable {
    public enum Command: String, Equatable {
        case noCache = "no-cache"
        case noStore = "no-store"
        case maxAge = "max-age"
        case sMaxAge = "s-maxage"
    }

    public let command: Command
    public let value: Int?

    public init(command: Command, value: Int?) {
        self.command = command
        self.value = value
    }

    /// :nodoc:
    public static func == (left: UBCacheResponseDirective, right: Command) -> Bool {
        return left.command == right
    }

    /// :nodoc:
    public static func == (left: Command, right: UBCacheResponseDirective) -> Bool {
        return right == left
    }
}

extension Array where Element == UBCacheResponseDirective {
    public init?(cacheControlHeader: String) {
        let cacheControlRegex = try! NSRegularExpression(pattern: "([a-z-]+)(=([0-9]+))?", options: [NSRegularExpression.Options.caseInsensitive])
        let matches = cacheControlRegex.matches(in: cacheControlHeader, options: [], range: NSRange(cacheControlHeader.startIndex..., in: cacheControlHeader))
        var result: UBCacheResponseDirectives = []
        for match in matches {
            if match.numberOfRanges == 4, let range = Range(match.range(at: 0), in: cacheControlHeader) {
                if let directiveRange = Range(match.range(at: 1), in: cacheControlHeader), let valueRange = Range(match.range(at: 3), in: cacheControlHeader), let command = UBCacheResponseDirective.Command(rawValue: String(cacheControlHeader[directiveRange])) {
                    result.append(UBCacheResponseDirective(command: command, value: Int(String(cacheControlHeader[valueRange]))))
                } else if let command = UBCacheResponseDirective.Command(rawValue: String(cacheControlHeader[range])) {
                    result.append(UBCacheResponseDirective(command: command, value: nil))
                }
            }
        }

        if result.isEmpty {
            return nil
        }
        self = result
    }

    public var cachingAllowed: Bool {
        return !contains(where: {
            $0 == UBCacheResponseDirective.Command.noCache || $0 == UBCacheResponseDirective.Command.noStore
        })
    }

    public var maxAge: Int? {
        return first(where: { $0 == UBCacheResponseDirective.Command.maxAge || $0 == UBCacheResponseDirective.Command.sMaxAge })?.value
    }
}
