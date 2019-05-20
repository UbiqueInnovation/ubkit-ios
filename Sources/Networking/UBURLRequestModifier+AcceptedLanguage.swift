//
//  UBURLRequestModifier+AcceptedLanguage.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 01.04.19.
//

import Foundation

/// Adds the accepted languages to a request
public class UBURLRequestAcceptedLanguageModifier: UBURLRequestModifier {
    /// :nodoc:
    private let serial = DispatchQueue(label: "Accepted Language")

    /// :nodoc:
    public var _localization: UBLocalization
    /// The localization to use for the language list.
    public var localization: UBLocalization {
        get {
            return serial.sync {
                _localization
            }
        }
        set {
            serial.sync {
                _localization = newValue
            }
        }
    }

    /// :nodoc:
    public var _includeRegion: Bool
    /// If the region information (if present) should be appended to the language.
    public var includeRegion: Bool {
        get {
            return serial.sync {
                _includeRegion
            }
        }
        set {
            serial.sync {
                _includeRegion = newValue
            }
        }
    }

    /// Creates a request modifier that add accepted languages information.
    ///
    /// - Parameters:
    ///   - includeRegion: If the region information (if present) should be appended to the language.
    ///   - localization: The localization to use for the language list.
    public init(includeRegion: Bool, localization: UBLocalization) {
        _localization = localization
        _includeRegion = includeRegion
    }

    /// :nodoc:
    public func modifyRequest(_ originalRequest: UBURLRequest, completion: @escaping (Result<UBURLRequest>) -> Void) {
        // Standard: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language

        let languages = localization.preferredLanguages(stripRegionInformation: !includeRegion)

        guard languages.isEmpty == false else {
            completion(.success(originalRequest))
            return
        }

        let languageCodes = languages.map { $0.identifier }
        var components: [String] = []
        for (index, languageCode) in languageCodes.enumerated() {
            let q = 1.0 - (Double(index) * 0.1)
            components.append("\(languageCode);q=\(q)")
            if q <= 0.1 {
                break
            }
        }
        let headerValue = components.joined(separator: ",")
        var newRequest = originalRequest
        newRequest.setHTTPHeaderField(UBHTTPHeaderField(key: .acceptLanguage, value: headerValue))
        completion(.success(newRequest))
    }
}
