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
            let oldLanguageCode = appLocalization.locale.languageCode!
            let newLanguageCode = oldLanguageCode == "en" ? "fr" : "en"
            try UBFoundation.setLanguage(languageCode: newLanguageCode, regionCode: appLocalization.locale.regionCode)
            XCTAssertEqual(appLocalization.locale.languageCode, newLanguageCode)
            XCTAssertEqual(appLocalization.locale.identifier, frameworkLocalization.locale.identifier)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
