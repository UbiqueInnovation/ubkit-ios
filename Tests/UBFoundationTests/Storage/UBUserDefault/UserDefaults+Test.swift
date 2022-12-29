//
//  UserDefaults+Test.swift
//  UBFoundation
//
//  Created by Zeno Koller on 16.01.20.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

extension UserDefaults {
    static func makeTestInstance(for functionName: StaticString = #function, inFile fileName: StaticString = #file) -> UserDefaults {
        let className = "\(fileName)".split(separator: ".")[0]
        let testName = "\(functionName)".split(separator: "(")[0]
        let suiteName = "\(className).\(testName)"

        let defaults = self.init(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
#endif
