//
//  File.swift
//
//
//  Created by Patrick Amrein on 26.08.22.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

extension NSError {
    public var errorCode: String {
        if let codedError = self as? UBCodedError {
            return codedError.errorCode
        } else {
            return "[\(self.mapDomain(self.domain))-\(self.code)]"
        }
    }

    func mapDomain(_ domain: String) -> String {
        switch domain {
            case "kCFErrorDomainCFNetwork":
                return "CFN"
            default:
                if domain.contains("kCFErrorDomain") {
                    let domainPrefix = domain.replacingOccurrences(of: "kCFErrorDomain", with: "").replacingOccurrences(of: "CF", with: "").prefix(1)
                    return "CF\(domainPrefix)"
                }
                return domain
        }
    }
}
#endif
