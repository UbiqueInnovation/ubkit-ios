//
//  UBButton.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

/// MARK: - Basic text button class that implements basic button properties

class UBButton : UIButton
{
    // MARK: - Callback for .touchDown action
    public var touchDownCallback : (() -> ())? = nil

    // MARK: - Callback for .touchUpInside action
    public var touchUpCallback : (() -> ())? = nil

    // MARK: - Title for button
    public var title : String?
    {
        didSet { self.titleLabel?.text = title }
    }

    // MARK: - Highlight view

    /// Color of highlight view
    public var highlightedBackgroundColor : UIColor? = UIColor.black.withAlphaComponent(0.2)
    {
        didSet { self.adjustHighlightView() }
    }

    /// Inset for x-Direction (e.g. for text buttons)
    public var highlightXInset : CGFloat = 0
    {
        didSet { self.adjustClipsToBounds() }
    }

    /// Inset for y-Direction (e.g. for text buttons)
    public var highlightYInset : CGFloat = 0
    {
        didSet { self.adjustClipsToBounds() }
    }

    /// Corner radius (e.g. for text buttons)
    public var highlightCornerRadius : CGFloat = 0
    {
        didSet { self.adjustHighlightView() }
    }

    private let highlightView = UIView()

    init()
    {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.clear

        self.titleLabel?.numberOfLines = 0;
        self.titleLabel?.textAlignment = .center;

        self.highlightView.alpha = 0;
        self.insertSubview(self.highlightView, at: 0)

        self.adjustClipsToBounds()
        self.adjustHighlightView()
        self.adjustsImageWhenHighlighted = false

        self.addTarget(self, action: #selector(touchDown), for: .touchDown)
        self.addTarget(self, action: #selector(touchUp), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()

        self.highlightView.frame = self.bounds.inset(by: UIEdgeInsets(top: self.highlightYInset, left: self.highlightXInset, bottom: self.highlightYInset, right: self.highlightXInset))
    }

    override var isHighlighted: Bool
    {
        get { return self.isHighlighted }

        set(highlighted)
        {
            super.isHighlighted = highlighted

            if highlighted
            {
                self.highlightView.alpha = 1.0
            }
            else
            {
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [.beginFromCurrentState, .allowUserInteraction, .allowAnimatedContent], animations: {
                        self.highlightView.alpha = 0.0
                }, completion: nil)
            }
        }
    }

    private func adjustClipsToBounds()
    {
        self.clipsToBounds = (self.highlightXInset >= 0) && (self.highlightYInset >= 0)
    }

    private func adjustHighlightView()
    {
        self.highlightView.backgroundColor = self.highlightedBackgroundColor
        self.highlightView.layer.cornerRadius = self.highlightCornerRadius
    }

    @objc private func touchDown()
    {
        self.touchDownCallback?()
    }

    @objc private func touchUp()
    {
        self.touchUpCallback?()
    }
}
