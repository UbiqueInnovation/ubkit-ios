//
//  GlobalLocalizationTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

@testable import UBFoundation
import XCTest

class GlobalLocalizationTests: XCTestCase {
    func testSetGlobalLanguage() {
        do {
            let oldLanguageCode = UBAppLocalization.locale.languageCode!
            let newLanguageCode = oldLanguageCode == "en" ? "fr" : "en"
            try UBFoundation.setLanguage(languageCode: newLanguageCode, regionCode: UBAppLocalization.locale.regionCode)
            XCTAssertEqual(UBAppLocalization.locale.languageCode, newLanguageCode)
            XCTAssertEqual(UBAppLocalization.locale.identifier, frameworkLocalization.locale.identifier)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
