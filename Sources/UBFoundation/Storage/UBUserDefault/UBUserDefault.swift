//
//  UBUserDefault.swift
//  UBFoundation
//
//  Created by Zeno Koller on 02.02.20.
//

import Foundation

/// A value which can be stored in `UserDefaults` using the `UBUserDefault` property wrapper.
///
/// Plist-Compatible values (instances or collections of Data, String,
/// Number, Date, Array, or Dictionary) are supported out of the box.
/// To store `Codable` types in `UserDefaults`, please conform to `UBCodable`.
/// To store `RawRepresentable` types in `UserDefaults`, please conform to `UBRawRepresentable`.
public protocol UBUserDefaultValue {
    init?(with object: Any)
    func object() -> Any?
}

public extension UBUserDefaultValue {
    init?(with object: Any) {
        guard let value = object as? Self else { return nil }
        self = value
    }

    func object() -> Any? { self }
}

// MARK: - Plist-Compatible Values

/// The types that can be stored in `UserDefaults` out of the box.
protocol UBPListValue: UBUserDefaultValue {}

extension Data: UBPListValue {}
extension NSData: UBPListValue {}

extension String: UBPListValue {}
extension NSString: UBPListValue {}

extension Date: UBPListValue {}
extension NSDate: UBPListValue {}

extension NSNumber: UBPListValue {}
extension Int: UBPListValue {}
extension Int8: UBPListValue {}
extension Int16: UBPListValue {}
extension Int32: UBPListValue {}
extension Int64: UBPListValue {}
extension UInt: UBPListValue {}
extension UInt8: UBPListValue {}
extension UInt16: UBPListValue {}
extension UInt32: UBPListValue {}
extension UInt64: UBPListValue {}
extension Double: UBPListValue {}
extension Float: UBPListValue {}

// MARK: - Bool

extension Bool: UBUserDefaultValue {
    public init?(with object: Any) {
        if let value = object as? Self {
            self = value
            return
        }

        // If a UserDefault value is passed via launchArgument for XCUITest it is always passed as a string
        // therefore we try to interpret the string as a fallback
        if let string = object as? String {
            switch string.lowercased() {
                case "true", "t", "yes", "y", "1":
                    self = true
                    return
                case "false", "f", "no", "n", "0":
                    self = false
                    return
                default:
                    return nil
            }
        }

        return nil
    }

    public func object() -> Any? { self }
}

// MARK: - Codable Values

public protocol UBCodable: Codable, UBUserDefaultValue {}

public extension UBUserDefaultValue where Self: UBCodable {
    init?(with object: Any) {
        guard let value = (object as? Data).flatMap({ try? JSONDecoder().decode(Self.self, from: $0) }) else { return nil }
        self = value
    }

    func object() -> Any? {
        try? JSONEncoder().encode(self)
    }
}

// MARK: - RawRepresentable Values

public protocol UBRawRepresentable: RawRepresentable, UBUserDefaultValue {}

public extension UBUserDefaultValue where Self: UBRawRepresentable {
    init?(with object: Any) {
        guard let value = object as? Self.RawValue else {
            return nil
        }
        self.init(rawValue: value)
    }

    func object() -> Any? {
        rawValue
    }
}

// MARK: - Arrays

extension Array: UBUserDefaultValue where Element: UBUserDefaultValue {
    public init?(with object: Any) {
        guard let array = object as? [Any] else { return nil }
        self = array.compactMap(Element.init(with:))
    }

    public func object() -> Any? {
        compactMap { $0.object() }
    }
}

// MARK: - Dictionaries

extension Dictionary: UBUserDefaultValue where Key == String, Value: UBUserDefaultValue {
    public init?(with object: Any) {
        guard let dict = object as? [String: Any] else { return nil }
        self = dict.compactMapValues(Value.init(with:))
    }

    public func object() -> Any? {
        compactMapValues { $0.object() }
    }
}

// MARK: - Optionals

extension Optional: UBUserDefaultValue where Wrapped: UBUserDefaultValue {
    public init?(with object: Any) {
        guard let value = Wrapped(with: object) else { return nil }
        self = .some(value)
    }

    public func object() -> Any? {
        switch self {
            case let .some(value):
                value.object()
            case .none:
                nil
        }
    }
}

// MARK: - UBUserDefault

/// Backs a variable of type `T` with storage in UserDefaults, where `T` conforms to
/// `UBUserDefaultValue`.
/// For optional types without a default value, please set `defaultValue` to nil.
/// Adapted from `https://gist.github.com/WorldDownTown/57382f9100af07d6e1f64c3ebe2e670a`.
///
/// Usage:
///       @UBUserDefault(key: "username_key", defaultValue: "")
///       var userName: String
///
///       @UBUserDefault(key: "maybeAnInteger", defaultValue: nil)
///       var maybeAnInteger: Int?
///
///       @UBUserDefault(key: "favoriteRecipes", defaultValue: [])
///       var favoriteRecipes: [Recipe] // where struct Recipe: UBCodable
///
///       @UBUserDefault(key: "lastUsedGpsMode", defaultValue: nil)
///       var lastUsedGpsMode: GpsMode? // where enum GpsMode: UBRawRepresentable
///
@propertyWrapper
public struct UBUserDefault<Value: UBUserDefaultValue> {
    let key: String
    let defaultValue: Value
    var userDefaults: UserDefaults

    /// :nodoc:
    public init(key: String, defaultValue: Value, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    /// :nodoc:
    public var wrappedValue: Value {
        get {
            userDefaults.object(forKey: key).flatMap(Value.init(with:))
                ?? defaultValue
        }
        set {
            newValue.object().map { userDefaults.set($0, forKey: key) }
                ?? userDefaults.removeObject(forKey: key)
        }
    }
}
