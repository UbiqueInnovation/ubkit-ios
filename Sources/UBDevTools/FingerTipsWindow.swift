//
//  FingerTipsWindow.swift
//
//
//  Created by Marco Zimmermann on 30.09.22.
//

import UIKit

class FingerTipsWindow: UIWindow {
    private var isActive: Bool = true
    private var fingerViews: [Int: FingerTipView] = [:]

    private var useMainRoot = true

    public func remove() {
        self.useMainRoot = false

        self.rootViewController?.view.removeFromSuperview()
        self.rootViewController = nil
        self.isHidden = true

        if #available(iOS 13, *) {
            windowScene = nil
        }
    }

    public func handleTouchEvent(_ event: UIEvent) {
        guard isActive else {
            super.sendEvent(event)
            return
        }

        self.handleEvent(event)

        super.sendEvent(event)
    }

    private func handleEvent(_ event: UIEvent) {
        guard let touches = event.allTouches else { return }

        for t in touches {
            switch t.phase {
                case .began:
                    let ftv = FingerTipView()
                    ftv.center = t.location(in: self)
                    self.addSubview(ftv)
                    self.fingerViews[t.hash] = ftv

                case .moved, .stationary:
                    if let ftv = self.fingerViews[t.hash] {
                        ftv.center = t.location(in: self)
                    }
                case .ended, .cancelled:
                    if let ftv = self.fingerViews[t.hash] {
                        ftv.fadeOut {
                            ftv.removeFromSuperview()
                            self.fingerViews.removeValue(forKey: t.hash)
                        }
                    }
                case .regionEntered, .regionMoved, .regionExited:
                    break
                @unknown default:
                    break
            }
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event)
    }

    override var rootViewController: UIViewController? {
        set { super.rootViewController = newValue }
        get {
            if let main = UIApplication.shared.windows.first(where: {
                !($0 is FingerTipsWindow)
            }), useMainRoot {
                return main.rootViewController
            }

            return super.rootViewController
        }
    }
}

class FingerTipView: UIImageView {
    private var timestamp: Int64 = 0
    private var removeAutomatically: Bool = false
    private var isFadingOut: Bool = false

    init() {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 50.0, height: 50.0)))
        self.layer.cornerRadius = 25.0

        self.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        self.layer.borderWidth = 2.0
        self.layer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fadeOut(_ completion: @escaping (() -> Void)) {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0.0
        } completion: { _ in
            completion()
        }
    }
}

extension UIWindow {
    static var associatedObjectHandle: UInt8 = 0

    static var sendSwizzled = false

    static func sendEventSwizzleWizzle() {
        guard let originalMethod = class_getInstanceMethod(UIWindow.self, #selector(sendEvent)), let swizzledMethod = class_getInstanceMethod(UIWindow.self, #selector(swizzled_sendEvent)), !Self.sendSwizzled
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
        Self.sendSwizzled = true
    }

    @objc func swizzled_sendEvent(_ event: UIEvent) {
        swizzled_sendEvent(event)
        if let w = objc_getAssociatedObject(self, &Self.associatedObjectHandle) as? FingerTipsWindow {
            w.handleTouchEvent(event)
        }
    }
}
