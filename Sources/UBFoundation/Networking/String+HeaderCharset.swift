//
//  String+HeaderCharset.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 22.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

extension String.Encoding {
    /// Returns the charset name of the encoding
    var charsetName: String? {
        let charsetEncoding = CFStringConvertNSStringEncodingToEncoding(rawValue)
        if let charsetName = CFStringConvertEncodingToIANACharSetName(charsetEncoding) {
            return charsetName as String
        } else {
            return nil
        }
    }
}
#endif
