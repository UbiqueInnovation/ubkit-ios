//
//  UBButton.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - Basic text button class that implements basic button properties

open class UBButton: UIButton {
    // MARK: - Callback for .touchDown action

    public var touchDownCallback: (() -> Void)?

    // MARK: - Callback for .touchUpInside action

    public var touchUpCallback: (() -> Void)?

    // MARK: - Title for button

    public var title: String? {
        didSet {
            setTitle(title, for: .normal)
        }
    }

    // MARK: - Highlight view

    /// Color of highlight view
    public var highlightedBackgroundColor: UIColor? = UIColor.black.withAlphaComponent(0.2) {
        didSet { adjustHighlightView() }
    }

    /// Inset for x-Direction (e.g. for text buttons)
    public var highlightXInset: CGFloat = 0 {
        didSet { adjustClipsToBounds() }
    }

    /// Inset for y-Direction (e.g. for text buttons)
    public var highlightYInset: CGFloat = 0 {
        didSet { adjustClipsToBounds() }
    }

    /// Corner radius (e.g. for text buttons)
    public var highlightCornerRadius: CGFloat = 0 {
        didSet { adjustHighlightView() }
    }

    private let highlightView = UIView()

    public init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.clear

        titleLabel?.numberOfLines = 0
        titleLabel?.textAlignment = .center

        highlightView.alpha = 0
        if let imageView = imageView {
            insertSubview(highlightView, belowSubview: imageView)
        } else {
            insertSubview(highlightView, at: 0)
        }

        adjustClipsToBounds()
        adjustHighlightView()
        adjustsImageWhenHighlighted = false

        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: .touchUpInside)
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        highlightView.frame = bounds.inset(by: UIEdgeInsets(top: highlightYInset, left: highlightXInset, bottom: highlightYInset, right: highlightXInset))
    }

    open func setHighlighted(_ highlighted: Bool, animated: Bool = false) {
        super.isHighlighted = highlighted

        if highlighted {
            highlightView.alpha = 1.0
        } else {
            UIView.animate(withDuration: animated ? 0.4 : 0.0, delay: 0.0, options: [.beginFromCurrentState, .allowUserInteraction, .allowAnimatedContent], animations: {
                self.highlightView.alpha = 0.0
            }, completion: nil)
        }
    }

    override public var isHighlighted: Bool {
        get { super.isHighlighted }

        set(highlighted) {
            setHighlighted(highlighted)
        }
    }

    private func adjustClipsToBounds() {
        clipsToBounds = (highlightXInset >= 0) && (highlightYInset >= 0)
    }

    private func adjustHighlightView() {
        highlightView.backgroundColor = highlightedBackgroundColor
        highlightView.layer.cornerRadius = highlightCornerRadius
    }

    @objc private func touchDown() {
        touchDownCallback?()
    }

    @objc private func touchUp() {
        touchUpCallback?()
    }
}
