//
//  CacheDevTools.swift
//
//
//  Created by Marco Zimmermann on 03.10.22.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

class CacheDevTools {
    public static func currentSizes(_ cache: URLCache) -> String {
        var result = ""
        result = result + "Memory capacity: \(ByteCountFormatter.string(fromByteCount: Int64(cache.memoryCapacity), countStyle: .file))"
        result = result + "\nDisk capacity: \(ByteCountFormatter.string(fromByteCount: Int64(cache.diskCapacity), countStyle: .file))"
        result = result + "\nCurrent memory usage: \(ByteCountFormatter.string(fromByteCount: Int64(cache.currentMemoryUsage), countStyle: .file))"
        result = result + "\nCurrent disk usage: \(ByteCountFormatter.string(fromByteCount: Int64(cache.currentDiskUsage), countStyle: .file))"
        return result
    }

    public static func clearCache(_ cache: URLCache) {
        cache.removeAllCachedResponses()
    }
}
#endif
