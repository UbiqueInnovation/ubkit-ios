//
//  LocalizationTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import UBFoundation
import XCTest

class LocalizationTests: XCTestCase {
    let testBundle: Bundle = {
        guard let testBundlePath = Bundle(for: LocalizationTests.self).path(forResource: "LocalizationTestBundle", ofType: nil),
            let testBundle = Bundle(path: testBundlePath) else {
            fatalError("No test bundle found")
        }
        return testBundle
    }()

    func testPreferredLanguages() {
        let frenchCHLocalization = Localization(locale: Locale(identifier: "fr_CH"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNil(frenchCHLocalization.bundle)

        let test1 = frenchCHLocalization.preferredLanguages(stripRegionInformation: true, preferredLanguages: ["en", "fr", "it"])
        XCTAssertEqual(test1.map({ $0.identifier }), ["fr", "en", "it"])

        let test2 = frenchCHLocalization.preferredLanguages(stripRegionInformation: false, preferredLanguages: ["fr", "en", "it"])
        XCTAssertEqual(test2.map({ $0.identifier }), ["fr_CH", "fr", "en", "it"])
    }

    func testPreferredLanguagesEdgeCases() {
        let localization = Localization(locale: Locale(identifier: "-"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNil(localization.bundle)

        let test1 = localization.preferredLanguages(stripRegionInformation: true, preferredLanguages: ["_", "@"])
        XCTAssertEqual(test1.map({ $0.identifier }), ["-", "_", "@"])
    }

    func testAvailableLanguages() {
        let languagesStripped = Localization.availableLanguages(stripRegionInformation: true, bundle: testBundle)
        XCTAssertEqual(languagesStripped.map({ $0.identifier }), ["en"])

        let languagesNotStripped = Localization.availableLanguages(stripRegionInformation: false, bundle: testBundle)
        XCTAssertEqual(Set(languagesNotStripped.map({ $0.identifier })), Set(["en", "en-IN"]))
    }

    func testBundleLoadFromIdentifier() {
        let englishIndian = Localization(locale: Locale(identifier: "en_IN"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNotNil(englishIndian.bundle)

        let english = Localization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNotNil(english.bundle)
    }

    func testBundleLoadFromLanguageOnly() {
        let englishIndian = Localization(locale: Locale(identifier: "en_CH"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNotNil(englishIndian.bundle)
    }

    func testCoding() {
        do {
            let jsonEncoder = JSONEncoder()
            let english = Localization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
            XCTAssertNotNil(english.bundle)
            let data = try jsonEncoder.encode(english)
            let jsonDecoder = JSONDecoder()
            let decodedEnglish = try jsonDecoder.decode(Localization.self, from: data)
            XCTAssertNotNil(decodedEnglish.bundle)
            XCTAssertEqual(english.locale.identifier, decodedEnglish.locale.identifier)
            XCTAssertEqual(english.bundle?.bundlePath, decodedEnglish.bundle?.bundlePath)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCodingNoBundle() {
        do {
            let jsonEncoder = JSONEncoder()
            let french = Localization(locale: Locale(identifier: "fr"), baseBundle: testBundle, notificationCenter: NotificationCenter())
            XCTAssertNil(french.bundle)
            let data = try jsonEncoder.encode(french)
            let jsonDecoder = JSONDecoder()
            let decodedEnglish = try jsonDecoder.decode(Localization.self, from: data)
            XCTAssertNil(decodedEnglish.bundle)
            XCTAssertEqual(french.locale.identifier, decodedEnglish.locale.identifier)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSetLanguage() {
        let localization = Localization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        let initialBundlePath = localization.bundle?.bundlePath
        XCTAssertNotNil(localization.bundle)
        XCTAssertNoThrow(try localization.setLanguage(languageCode: "en", regionCode: "IN", baseLocale: localization.locale, baseBundle: testBundle))
        XCTAssertEqual(localization.locale.identifier, "en_IN")
        XCTAssertEqual(localization.locale.languageCode, "en")
        XCTAssertNotNil(localization.bundle)
        XCTAssertNotEqual(localization.bundle?.bundlePath, initialBundlePath)
        XCTAssertNoThrow(try localization.setLanguage(languageCode: "fr", regionCode: nil, baseLocale: localization.locale, baseBundle: testBundle))
        XCTAssertNil(localization.bundle)
        XCTAssertEqual(localization.locale.identifier, "fr")
    }

    func testFormatters() {
        let localization = Localization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())

        let df = DateFormatter(localization: localization)
        XCTAssertEqual(df.locale.identifier, localization.locale.identifier)

        let dcf = DateComponentsFormatter(localization: localization)
        XCTAssertEqual(dcf.calendar?.identifier, localization.locale.calendar.identifier)

        let dif = DateIntervalFormatter(localization: localization)
        XCTAssertEqual(dif.calendar.identifier, localization.locale.calendar.identifier)
        XCTAssertEqual(dif.locale.identifier, localization.locale.identifier)

        let nf = NumberFormatter(localization: localization)
        XCTAssertEqual(nf.locale.identifier, localization.locale.identifier)

        let lf = LengthFormatter(localization: localization)
        XCTAssertEqual(lf.numberFormatter.locale.identifier, localization.locale.identifier)

        let mf = MassFormatter(localization: localization)
        XCTAssertEqual(mf.numberFormatter.locale.identifier, localization.locale.identifier)
    }

    func testNotifications() {
        let localization = Localization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: .default)
        expectation(forNotification: LocalizationNotification.localeWillChange, object: localization) { (notification) -> Bool in
            let old = notification.userInfo?[LocalizationNotification.oldLocaleKey] as? Locale
            let new = notification.userInfo?[LocalizationNotification.newLocaleKey] as? Locale
            return old?.identifier == "en" && new?.identifier == "fr"
        }

        expectation(forNotification: LocalizationNotification.localeDidChange, object: localization) { (notification) -> Bool in
            let old = notification.userInfo?[LocalizationNotification.oldLocaleKey] as? Locale
            let new = notification.userInfo?[LocalizationNotification.newLocaleKey] as? Locale
            return old?.identifier == "en" && new?.identifier == "fr"
        }

        XCTAssertNoThrow(try localization.setLanguage(languageCode: "fr", regionCode: nil, baseLocale: localization.locale, baseBundle: testBundle))
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testStringLocalization() {
        do {
            let english = Localization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
            let englishIndia = Localization(locale: Locale(identifier: "en_IN"), baseBundle: testBundle, notificationCenter: NotificationCenter())
            let englishLang = try "lang".localized(localization: english)
            let englishIndianLang = try "lang".localized(localization: englishIndia)
            XCTAssertEqual(englishLang, "English")
            XCTAssertEqual(englishIndianLang, "English India")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testStringLocalizationNoBundle() {
        let french = Localization(locale: Locale(identifier: "fr"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertThrowsError(try "lang".localized(localization: french), "Expected error thrown") { error in
            XCTAssertEqual(error as? LocalizationError, LocalizationError.bundelNotFound)
        }
    }

    func testLocaleIsCurrent() {
        let currentLocale = Locale.current
        XCTAssertTrue(currentLocale.isCurrent)
        let aLocale = Locale(identifier: "fr")
        XCTAssertFalse(aLocale.isCurrent)
    }

    func testResetLocale() {
        let localization = Localization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertFalse(localization.locale.isCurrent)
        localization.resetLocaleToCurrent()
        XCTAssertTrue(localization.locale.isCurrent)
    }
}
