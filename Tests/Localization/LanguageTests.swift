//
//  LanguageTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import UBFoundation
import XCTest

class LanguageTests: XCTestCase {
    let englishLocalization = Localization(locale: Locale(identifier: "en_US"), baseBundle: Bundle(for: LanguageTests.self), notificationCenter: NotificationCenter())
    let frenchLocalization = Localization(locale: Locale(identifier: "fr"), baseBundle: Bundle(for: LanguageTests.self), notificationCenter: NotificationCenter())

    let testData: [(id: String, english: String, french: String, native: String)] = [
        ("en", "English", "anglais", "English"),
        ("fr", "French", "français", "français"),
        ("it", "Italian", "italien", "italiano"),
        ("de", "German", "allemand", "Deutsch"),
        ("en_CH", "English (Switzerland)", "anglais (Suisse)", "English (Switzerland)"),
        ("fr_CH", "French (Switzerland)", "français (Suisse)", "français (Suisse)"),
        ("it_CH", "Italian (Switzerland)", "italien (Suisse)", "italiano (Svizzera)"),
        ("de_CH", "German (Switzerland)", "allemand (Suisse)", "Deutsch (Schweiz)")
    ]

    let testFalseData: [String] = [
        "xx",
        "fr/dc",
        "123"
    ]

    func testDisplayNameSuccess() {
        for test in testData {
            let language = Localization.Language(identifier: test.id)
            XCTAssertEqual(language.displayName(englishLocalization), test.english)
            XCTAssertEqual(language.displayName(frenchLocalization), test.french)
            XCTAssertEqual(language.displayNameInNativeLanguage, test.native)
        }
    }

    func testDisplayNameFailure() {
        for test in testFalseData {
            let language = Localization.Language(identifier: test)
            XCTAssertNil(language.displayName(englishLocalization))
            XCTAssertNil(language.displayName(frenchLocalization))
            XCTAssertNil(language.displayNameInNativeLanguage)
        }
    }

    func testEquality() {
        let languageA = Localization.Language(identifier: testData.first!.id)
        let languageB = Localization.Language(identifier: testData.first!.id)
        XCTAssertEqual(languageA, languageB)
    }

    func testInequality() {
        let languageA = Localization.Language(identifier: testData.first!.id)
        let languageB = Localization.Language(identifier: testData.last!.id)
        XCTAssertNotEqual(languageA, languageB)
    }

    func testDescription() {
        let test = testData.first!
        let language = Localization.Language(identifier: test.id)
        XCTAssertEqual(String(describing: language), test.native)
    }

    func testDescriptionOfUnknownLanguage() {
        let test = testFalseData.first!
        let language = Localization.Language(identifier: test)
        XCTAssertEqual(String(describing: language), test)
    }
}
