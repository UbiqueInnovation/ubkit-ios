//
//  LocalizationTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 19.03.19.
//

import UBFoundation
import XCTest

class LocalizationTests: XCTestCase {
    lazy var testBundle: Bundle = {
        guard let testBundlePath = Bundle.module.path(forResource: "TestResources/LocalizationTestBundle", ofType: nil),
              let testBundle = Bundle(path: testBundlePath) else {
            fatalError("No test bundle found")
        }
        return testBundle
    }()

    func testPreferredLanguages() {
        let frenchCHLocalization = UBLocalization(locale: Locale(identifier: "fr_CH"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNil(frenchCHLocalization.localizedBundle)

        let test1 = frenchCHLocalization.preferredLanguages(stripRegionInformation: true, preferredLanguages: ["en", "fr", "it"])
        XCTAssertEqual(test1.map(\.identifier), ["fr", "en", "it"])

        let test2 = frenchCHLocalization.preferredLanguages(stripRegionInformation: false, preferredLanguages: ["fr", "en", "it"])
        XCTAssertEqual(test2.map(\.identifier), ["fr_CH", "fr", "en", "it"])
    }

    func testPreferredLanguagesEdgeCases() {
        let localization = UBLocalization(locale: Locale(identifier: "-"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNil(localization.localizedBundle)

        let test1 = localization.preferredLanguages(stripRegionInformation: true, preferredLanguages: ["_", "@"])
        XCTAssertEqual(test1.map(\.identifier), ["-", "_", "@"])
    }

    func testAvailableLanguages() {
        let languagesStripped = UBLocalization.availableLanguages(stripRegionInformation: true, bundle: testBundle)
        XCTAssertEqual(languagesStripped.map(\.identifier), ["en"])

        let languagesNotStripped = UBLocalization.availableLanguages(stripRegionInformation: false, bundle: testBundle)
        XCTAssertEqual(Set(languagesNotStripped.map(\.identifier)), Set(["en", "en-IN"]))
    }

    func testBundleLoadFromIdentifier() {
        let englishIndian = UBLocalization(locale: Locale(identifier: "en_IN"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNotNil(englishIndian.localizedBundle)

        let english = UBLocalization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNotNil(english.localizedBundle)
    }

    func testBundleLoadFromLanguageOnly() {
        let englishIndian = UBLocalization(locale: Locale(identifier: "en_CH"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertNotNil(englishIndian.localizedBundle)
    }

    func testCoding() {
        do {
            let jsonEncoder = JSONEncoder()
            let english = UBLocalization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
            XCTAssertNotNil(english.localizedBundle)
            let data = try jsonEncoder.encode(english)
            let jsonDecoder = JSONDecoder()
            let decodedEnglish = try jsonDecoder.decode(UBLocalization.self, from: data)
            XCTAssertNotNil(decodedEnglish.localizedBundle)
            XCTAssertEqual(english.locale.identifier, decodedEnglish.locale.identifier)
            XCTAssertEqual(english.localizedBundle?.bundlePath, decodedEnglish.localizedBundle?.bundlePath)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCodingNoBundle() {
        do {
            let jsonEncoder = JSONEncoder()
            let french = UBLocalization(locale: Locale(identifier: "fr"), baseBundle: testBundle, notificationCenter: NotificationCenter())
            XCTAssertNil(french.localizedBundle)
            let data = try jsonEncoder.encode(french)
            let jsonDecoder = JSONDecoder()
            let decodedEnglish = try jsonDecoder.decode(UBLocalization.self, from: data)
            XCTAssertNil(decodedEnglish.localizedBundle)
            XCTAssertEqual(french.locale.identifier, decodedEnglish.locale.identifier)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSetLanguage() {
        let localization = UBLocalization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        let initialBundlePath = localization.localizedBundle?.bundlePath
        XCTAssertNotNil(localization.localizedBundle)
        XCTAssertNoThrow(try localization.setLanguage(languageCode: "en", regionCode: "IN", baseLocale: localization.locale, baseBundle: testBundle))
        XCTAssertEqual(localization.locale.identifier, "en_IN")
        XCTAssertEqual(localization.locale.languageCode, "en")
        XCTAssertNotNil(localization.localizedBundle)
        XCTAssertNotEqual(localization.localizedBundle?.bundlePath, initialBundlePath)
        XCTAssertNoThrow(try localization.setLanguage(languageCode: "fr", regionCode: nil, baseLocale: localization.locale, baseBundle: testBundle))
        XCTAssertNil(localization.localizedBundle)
        XCTAssertEqual(localization.locale.identifier, "fr")
    }

    func testFormatters() {
        let localization = UBLocalization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())

        let df = DateFormatter(ub_localization: localization)
        XCTAssertEqual(df.locale.identifier, localization.locale.identifier)

        let dcf = DateComponentsFormatter(ub_localization: localization)
        XCTAssertEqual(dcf.calendar?.identifier, localization.locale.calendar.identifier)

        let dif = DateIntervalFormatter(ub_localization: localization)
        XCTAssertEqual(dif.calendar.identifier, localization.locale.calendar.identifier)
        XCTAssertEqual(dif.locale.identifier, localization.locale.identifier)

        let nf = NumberFormatter(ub_localization: localization)
        XCTAssertEqual(nf.locale.identifier, localization.locale.identifier)

        let lf = LengthFormatter(ub_localization: localization)
        XCTAssertEqual(lf.numberFormatter.locale.identifier, localization.locale.identifier)

        let mf = MassFormatter(ub_localization: localization)
        XCTAssertEqual(mf.numberFormatter.locale.identifier, localization.locale.identifier)
    }

    func testNotifications() {
        let localization = UBLocalization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: .default)
        expectation(forNotification: UBLocalizationNotification.localeWillChange, object: localization) { notification -> Bool in
            let old = notification.userInfo?[UBLocalizationNotification.oldLocaleKey] as? Locale
            let new = notification.userInfo?[UBLocalizationNotification.newLocaleKey] as? Locale
            return old?.identifier == "en" && new?.identifier == "fr"
        }

        expectation(forNotification: UBLocalizationNotification.localeDidChange, object: localization) { notification -> Bool in
            let old = notification.userInfo?[UBLocalizationNotification.oldLocaleKey] as? Locale
            let new = notification.userInfo?[UBLocalizationNotification.newLocaleKey] as? Locale
            return old?.identifier == "en" && new?.identifier == "fr"
        }

        XCTAssertNoThrow(try localization.setLanguage(languageCode: "fr", regionCode: nil, baseLocale: localization.locale, baseBundle: testBundle))
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testStringLocalization() {
        do {
            let english = UBLocalization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
            let englishIndia = UBLocalization(locale: Locale(identifier: "en_IN"), baseBundle: testBundle, notificationCenter: NotificationCenter())
            let englishLang = try "lang".ub_localized(localization: english)
            let englishIndianLang = try "lang".ub_localized(localization: englishIndia)
            XCTAssertEqual(englishLang, "English")
            XCTAssertEqual(englishIndianLang, "English India")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testStringLocalizationNoBundle() {
        let french = UBLocalization(locale: Locale(identifier: "fr"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertThrowsError(try "lang".ub_localized(localization: french), "Expected error thrown") { error in
            XCTAssertEqual(error as? UBLocalizationError, UBLocalizationError.bundelNotFound)
        }
    }

    func testLocaleIsCurrent() {
        let currentLocale = Locale.current
        XCTAssertTrue(currentLocale.ub_isCurrent)
        let aLocale = Locale(identifier: "fr")
        XCTAssertFalse(aLocale.ub_isCurrent)
    }

    func testResetLocale() {
        let localization = UBLocalization(locale: Locale(identifier: "en"), baseBundle: testBundle, notificationCenter: NotificationCenter())
        XCTAssertFalse(localization.locale.ub_isCurrent)
        localization.resetLocaleToCurrent()
        XCTAssertTrue(localization.locale.ub_isCurrent)
    }
}
