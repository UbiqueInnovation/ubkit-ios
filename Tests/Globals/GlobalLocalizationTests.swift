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
            let oldLanguageCode = AppLocalization.locale.languageCode!
            let newLanguageCode = oldLanguageCode == "en" ? "fr" : "en"
            try UBFoundation.setLanguage(languageCode: newLanguageCode, regionCode: AppLocalization.locale.regionCode)
            XCTAssertEqual(AppLocalization.locale.languageCode, newLanguageCode)
            XCTAssertEqual(AppLocalization.locale.identifier, frameworkLocalization.locale.identifier)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
