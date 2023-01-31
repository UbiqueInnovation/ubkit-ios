
import Foundation

extension Dictionary where Key == AnyHashable, Value: Any {
    /// Returns the value associated with the passed key by comparing using case insensitive option
    /// - Parameter key: The key to fetch it's value
    /// - Returns: The value associated with the passed key
    func getCaseInsensitiveValue(key: AnyHashable) -> Value? {
        if let directFound = self[key] {
            return directFound
        }

        var keys : [String] = []

        if let stringKey = key as? String {
            keys.append(stringKey)
        } else if let strings = key as? [String] {
            keys = strings
        }

        for key in keys {
            guard let caseInsensitiveElement = self.first(where: { dictionarykey, _ in
                guard let string = dictionarykey as? String else {
                    return false
                }
                let result = string.compare(key, options: .caseInsensitive)
                return result == .orderedSame
            }) else { continue }

            return caseInsensitiveElement.value
        }

        return nil
    }

    /// Set a value for the given key, replacing any other keys that match in an case insensitive manner.
    /// - Parameters:
    ///   - value: The value to set
    ///   - key: The key to use and replace all other matching keys
    mutating func setValue(_ value: Value, forCaseInsensitiveKey key: Key) {
        removeCaseInsensitiveValue(key: key)
        self[key] = value
    }

    /// Removes a value from the dictionary by comparing the key in a insensitive manner
    /// - Parameter key: The key to remove
    /// - Returns: `nil` if no key was found, otherwise the value associated with the key that was removed
    @discardableResult
    mutating func removeCaseInsensitiveValue(key: AnyHashable) -> Value? {
        if let directFound = removeValue(forKey: key) {
            return directFound
        }

        var keys : [String] = []

        if let stringKey = key as? String {
            keys.append(stringKey)
        } else if let strings = key as? [String] {
            keys = strings
        }

        for key in keys {
            for element in self {
                guard let string = element.key as? String,
                      string.compare(key, options: .caseInsensitive) == .orderedSame
                else {
                    continue
                }
                return removeValue(forKey: element.key)
            }
        }

        return nil
    }
}

extension Dictionary where Key == String, Value == String {
    /// Returns the value associated with the passed key by comparing using case insensitive option
    /// - Parameter key: The key to fetch it's value
    /// - Returns: The value associated with the passed key
    func getCaseInsensitiveValue(key: Key) -> Value? {
        if let directFound = self[key] {
            return directFound
        }
        for (dictionaryKey, value) in self {
            if dictionaryKey.compare(key, options: .caseInsensitive) == .orderedSame {
                return value
            }
        }
        return nil
    }

    /// Set a value for the given key, replacing any other keys that match in an case insensitive manner.
    /// - Parameters:
    ///   - value: The value to set
    ///   - key: The key to use and replace all other matching keys
    mutating func setValue(_ value: Value, forCaseInsensitiveKey key: Key) {
        removeCaseInsensitiveValue(key: key)
        self[key] = value
    }

    /// Removes a value from the dictionary by comparing the key in a insensitive manner
    /// - Parameter key: The key to remove
    /// - Returns: `nil` if no key was found, otherwise the value associated with the key that was removed
    @discardableResult
    mutating func removeCaseInsensitiveValue(key: Key) -> Value? {
        if let directFound = removeValue(forKey: key) {
            return directFound
        }
        for element in self {
            guard key.compare(element.key, options: .caseInsensitive) == .orderedSame else {
                continue
            }
            return removeValue(forKey: element.key)
        }
        return nil
    }
}
