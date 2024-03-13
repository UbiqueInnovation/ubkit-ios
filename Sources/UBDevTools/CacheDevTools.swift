//
//  CacheDevTools.swift
//
//
//  Created by Marco Zimmermann on 03.10.22.
//

import Foundation

enum CacheDevTools {
    public static var caches: [(id: String, cache: URLCache)] {
        [(id: "Shared", cache: URLCache.shared)] + additionalCaches
    }

    public static var additionalCaches: [(id: String, cache: URLCache)] = []

    public static var cachedCacheSizes: [String: String] = [:]

    public static func currentSizes(_ id: String, updateValue: UUID) -> String {
        if let s = cachedCacheSizes[id] {
            return s
        }
        guard let cache = caches.first(where: { $0.id == id })?.cache else {
            return "Cache with id \(id) not registered"
        }

        var result = ""
        result = result + "Memory capacity: \(ByteCountFormatter.string(fromByteCount: Int64(cache.memoryCapacity), countStyle: .file))"
        result = result + "\nDisk capacity: \(ByteCountFormatter.string(fromByteCount: Int64(cache.diskCapacity), countStyle: .file))"
        result = result + "\nCurrent memory usage: \(ByteCountFormatter.string(fromByteCount: Int64(cache.currentMemoryUsage), countStyle: .file))"
        result = result + "\nCurrent disk usage: \(ByteCountFormatter.string(fromByteCount: Int64(cache.currentDiskUsage), countStyle: .file))"

        cachedCacheSizes[id] = result

        return result
    }

    public static func clearCache(_ id: String) {
        guard let cache = caches.first(where: { $0.id == id })?.cache else {
            return
        }
        cache.removeAllCachedResponses()
        cachedCacheSizes[id] = nil
    }

    public static func clearCache(_ cache: URLCache) {
        cache.removeAllCachedResponses()
    }
}
