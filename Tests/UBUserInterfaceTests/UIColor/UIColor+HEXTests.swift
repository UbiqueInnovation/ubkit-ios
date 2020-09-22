//
//  UIColor+HEXTests.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 26.03.19.
//

import UBUserInterface
import XCTest

class UIColor_HEXTests: XCTestCase {
    func testHexParsingSuccess() {
        let testData = ["#000", "#57c3b5", "#f24851", "#F3c0", "#b87829bb", "000", "57c3b5", "f24851", "F3c0", "b87829bb"]
        for test in testData {
            let color = UIColor(ub_hexString: test)
            XCTAssertNotNil(color)
        }
    }

    func testHexParsingFailure() {
        let testData = ["#00", "#57m3b5", "#f2485", "F", "#b87829bbb", "", "#", "@fff", "#999.3"]
        for test in testData {
            let color = UIColor(ub_hexString: test)
            XCTAssertNil(color)
        }
    }

    func testColorEquality() {
        // We cannot use UIColor.white as it has a different color space
        let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        XCTAssertEqual(white, UIColor(ub_hexString: "#FFF"))
        XCTAssertEqual(white, UIColor(ub_hexString: "#FFFF"))
        XCTAssertEqual(white, UIColor(ub_hexString: "#FFFFFF"))
        XCTAssertEqual(white, UIColor(ub_hexString: "#FFFFFFFF"))

        let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(black, UIColor(ub_hexString: "#000"))
        XCTAssertEqual(black, UIColor(ub_hexString: "#000F"))
        XCTAssertEqual(black, UIColor(ub_hexString: "#000000"))
        XCTAssertEqual(black, UIColor(ub_hexString: "#000000FF"))

        let blueTransparent = UIColor(red: 0, green: 0, blue: 1, alpha: 0.6)
        XCTAssertEqual(blueTransparent, UIColor(ub_hexString: "#00F9"))
        XCTAssertEqual(blueTransparent, UIColor(ub_hexString: "#0000FF99"))
    }

    func testHexRepresentation() {
        let testData: [(test: String, result: String)] = [
            ("#FFF", "#FFFFFF"),
            ("#abc", "#AABBCC"),
            ("245690", "#245690"),
            ("ACE3", "#AACCEE33"),
            ("#aabbcc99", "#AABBCC99")
        ]
        for test in testData {
            let color = UIColor(ub_hexString: test.test)
            XCTAssertNotNil(color)
            XCTAssertEqual(color?.ub_hexString, test.result)
        }
    }

    func testHexRepresentationStandardColors() {
        let testData: [(test: UIColor, result: String)] = [
            (.white, "#FFFFFF"),
            (.black, "#000000"),
            (.red, "#FF0000")
        ]
        for test in testData {
            XCTAssertEqual(test.test.ub_hexString, test.result)
        }
    }

    func testParsingPerformance() {
        let testData = ["#FFF", "#FFFF", "#FFFFFF", "#FFFFFFFF", "#000", "#0000", "#000000", "#00000000", "#A12", "#B12"]
        measure {
            for _ in 1 ... 100 {
                testData.forEach { _ = UIColor(ub_hexString: $0) }
            }
        }
    }
}
