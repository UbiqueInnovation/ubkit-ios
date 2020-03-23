//
//  DefaultCachingPolicy.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 23.03.20.
//

import Foundation

public enum DefaultCachingPolicy {
    case noCache
    case cache(userInfo: [AnyHashable: Any])
}

public protocol DefaultCachingPolicyProvider {
    func defaultCaching(response: HTTPURLResponse) -> DefaultCachingPolicy
}

public struct DefaultNoCaching: DefaultCachingPolicyProvider {
    public func defaultCaching(response _: HTTPURLResponse) -> DefaultCachingPolicy {
        return .noCache
    }
}

public struct DefaultCaching: DefaultCachingPolicyProvider {
    public func defaultCaching(response _: HTTPURLResponse) -> DefaultCachingPolicy {
        return .cache(userInfo: [:])
    }
}
