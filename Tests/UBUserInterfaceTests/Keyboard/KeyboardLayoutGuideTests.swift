//
//  KeyboardLayoutGuideTests.swift
//  UBFoundation iOS Tests
//
//  Created by Joseph El Mallah on 26.03.19.
//

import UBUserInterface
import XCTest

@MainActor
class KeyboardLayoutGuideTests: XCTestCase {
    func testKeyboardReaction() {
        // Setup the hierarchy
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 600))
        window.initializeForKeyboardLayoutGuide()

        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
        let referenceView = UIView()

        window.addSubview(view)
        view.addSubview(referenceView)

        referenceView.translatesAutoresizingMaskIntoConstraints = false
        referenceView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        referenceView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        referenceView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        referenceView.bottomAnchor.constraint(equalTo: view.ub_keyboardLayoutGuide.topAnchor).isActive = true

        // Check that the layout is correct
        view.layoutIfNeeded()
        XCTAssertEqual(referenceView.frame.maxY, view.frame.height)

        // Open the keyboard
        let keyboardRect = CGRect(x: 0, y: 400, width: 300, height: 200)
        let keyboardNotification = Notification(name: UIResponder.keyboardWillChangeFrameNotification, object: nil, userInfo: [UIResponder.keyboardFrameEndUserInfoKey: keyboardRect])
        NotificationCenter.default.post(keyboardNotification)

        // Check if the view moved
        view.layoutIfNeeded()
        XCTAssertEqual(referenceView.frame.maxY, view.frame.height - (window.frame.height - view.frame.height))

        // Hide the keyboard
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil)

        // Cehck if the view returned to original position
        view.layoutIfNeeded()
        XCTAssertEqual(referenceView.frame.maxY, view.frame.height)
    }

    func testDeinit() {
        weak var keyboard: UILayoutGuide?
        var view: UIView?

        autoreleasepool {
            view = UIView()
            keyboard = view?.ub_keyboardLayoutGuide
            XCTAssertNotNil(keyboard)
            XCTAssertEqual(keyboard, view?.ub_keyboardLayoutGuide)
            view = nil
        }

        XCTAssertNil(keyboard)
    }
}
