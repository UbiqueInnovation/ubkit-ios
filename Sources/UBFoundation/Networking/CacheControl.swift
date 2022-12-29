//
//  CacheControl.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 04.04.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

/// A group of cache directives
public typealias UBCacheResponseDirectives = [UBCacheResponseDirective]

/// A cache control directive
public struct UBCacheResponseDirective: Hashable {
    /// A cache control directive command
    public enum Command: String, Equatable {
        /// A no cache command
        case noCache = "no-cache"
        /// A no store command
        case noStore = "no-store"
        /// A max age command
        case maxAge = "max-age"
        /// An s-max age command
        case sMaxAge = "s-maxage"
    }

    /// The cache control directive command
    public let command: Command
    /// The value  of the command. If present.
    public let value: Int?

    /// Initializes a cache control directive.
    ///
    /// - Parameters:
    ///   - command: The command
    ///   - value: The value
    public init(command: Command, value: Int?) {
        self.command = command
        self.value = value
    }

    /// :nodoc:
    public static func == (left: UBCacheResponseDirective, right: Command) -> Bool {
        left.command == right
    }

    /// :nodoc:
    public static func == (left: Command, right: UBCacheResponseDirective) -> Bool {
        right == left
    }
}

public extension Array where Element == UBCacheResponseDirective {
    /// Initializes and array of cache control commands from a cache control header string
    ///
    /// - Parameter cacheControlHeader: The cache control header string
    init?(cacheControlHeader: String) {
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

    /// Checks is cacjing is allowed on the group of cache controle
    var cachingAllowed: Bool {
        !contains(where: {
            $0 == UBCacheResponseDirective.Command.noCache || $0 == UBCacheResponseDirective.Command.noStore
        })
    }

    /// Check if there is a max age on the cache control group
    var maxAge: Int? {
        first(where: { $0 == UBCacheResponseDirective.Command.maxAge || $0 == UBCacheResponseDirective.Command.sMaxAge })?.value
    }
}
#endif
