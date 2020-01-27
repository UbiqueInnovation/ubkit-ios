//
//  UBUserDefaultsStored.swift
//  UBFoundation
//
//  Created by Zeno Koller on 14.01.20.
//

import Foundation

/// Backs a variable of type `T` with storage in UserDefaults, where `T` conforms to
/// `PropertyListValue`. For more complex types conforming to `Codable`, please
/// use `UBUserDefaultsJSONStored`
///
/// Usage:
///       @UBUserDefaultsStored(key: "username_key", defaultValue: "" )
///       var userName: String
///
/// Based on https://gist.github.com/LeeKahSeng/20e0c3602d1141af3bcff45f1f02df10
@propertyWrapper
public struct UBUserDefaultsStored<T: PropertyListValue> {
    /// The key of the UserDefaults entry
    private let key: String
    /// The default value of the backing UserDefaults entry
    private let defaultValue: T
    /// The UserDefaults used for storage
    var userDefaults: UserDefaults

    /// :nodoc:
    public init(key: String, defaultValue: T, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    /// :nodoc:
    public var wrappedValue: T {
        get {
            return userDefaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}

/// A type that can be stored in `UserDefaults`.
///
/// From the `UserDefaults Documentation`
/// "NSUserDefaults stores Property List objects (NSString, NSData, NSNumber, NSDate, NSArray, and NSDictionary) identified by NSString keys"
public protocol PropertyListValue {}

extension Data: PropertyListValue {}
extension NSData: PropertyListValue {}

extension String: PropertyListValue {}
extension NSString: PropertyListValue {}

extension Date: PropertyListValue {}
extension NSDate: PropertyListValue {}

extension NSNumber: PropertyListValue {}
extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Int8: PropertyListValue {}
extension Int16: PropertyListValue {}
extension Int32: PropertyListValue {}
extension Int64: PropertyListValue {}
extension UInt: PropertyListValue {}
extension UInt8: PropertyListValue {}
extension UInt16: PropertyListValue {}
extension UInt32: PropertyListValue {}
extension UInt64: PropertyListValue {}
extension Double: PropertyListValue {}
extension Float: PropertyListValue {}

extension Array: PropertyListValue where Element: PropertyListValue {}

extension Dictionary: PropertyListValue where Key == String, Value: PropertyListValue {}
