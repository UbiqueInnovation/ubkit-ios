//
//  UBLabel.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - UBLabelType Protocol

public protocol UBLabelType {
    var font: UIFont { get }
    var textColor: UIColor { get }
    var lineSpacing: CGFloat { get }
    var letterSpacing: CGFloat? { get }

    var isUppercased: Bool { get }

    /// between [0.0,1.0]: 0.0 disabled, 1.0 most hyphenation
    var hyphenationFactor: Float { get }

    var lineBreakMode: NSLineBreakMode { get }
}

// MARK: - UBLabel

open class UBLabel<T: UBLabelType>: UILabel {
    private let type: T

    /// Simple way to initialize Label with T and optional textColor to override standard color of type. Standard multiline and left-aligned.
    public init(_ type: T, textColor: UIColor? = nil, numberOfLines: Int = 0, textAlignment: NSTextAlignment = .left) {
        self.type = type

        super.init(frame: .zero)

        font = self.type.font
        self.textColor = textColor == nil ? self.type.textColor : textColor
        self.textAlignment = textAlignment
        self.numberOfLines = numberOfLines
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var text: String? {
        didSet { update() }
    }

    override public var attributedText: NSAttributedString? {
        didSet { updateAttributed() }
    }

    public var isHtmlContent: Bool = false {
        didSet { update() }
    }

    /// :nodoc:
    private func update() {
        guard var textContent = text else {
            super.attributedText = nil
            return
        }

        // uppercase the text if type is uppercased
        if type.isUppercased {
            textContent = textContent.uppercased()
        }

        // create attributed string
        let textString: NSMutableAttributedString

        // check html
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: isHtmlContent ? NSAttributedString.DocumentType.html : NSAttributedString.DocumentType.plain,
                .characterEncoding: String.Encoding.utf8.rawValue,
                .defaultAttributes: [:],
            ]

            textString = try NSMutableAttributedString(data: textContent.data(using: .utf8)!, options: options, documentAttributes: nil)
        } catch {
            textString = NSMutableAttributedString(string: textContent, attributes: [:])
        }

        if isHtmlContent {
            textString.ub_replaceFonts(with: font)
        }

        textString.ub_addAttributes(forLabelType: type, textAlignment: textAlignment, numberOfLines: numberOfLines)

        // set attributed text
        super.attributedText = textString
    }

    /// :nodoc:
    func updateAttributed() {
        guard let attributedText = attributedText else {
            // also triggers `attributedText = nil`
            super.text = nil
            return
        }

        super.attributedText =
            NSMutableAttributedString(attributedString: attributedText)
                .ub_addAttributes(forLabelType: type, textAlignment: textAlignment, numberOfLines: numberOfLines)
    }
}

extension NSMutableAttributedString {
    func ub_replaceFonts(with font: UIFont) {
        // from: https://stackoverflow.com/questions/19921972/
        let baseFontDescriptor = font.fontDescriptor
        var changes = [NSRange: UIFont]()

        enumerateAttribute(.font, in: NSRange(location: 0, length: length), options: []) { foundFont, range, _ in
            if let htmlTraits = (foundFont as? UIFont)?.fontDescriptor.symbolicTraits,
               let adjustedDescriptor = baseFontDescriptor.withSymbolicTraits(htmlTraits) {
                let newFont = UIFont(descriptor: adjustedDescriptor, size: font.pointSize)
                changes[range] = newFont
            }
        }

        changes.forEach { range, newFont in
            removeAttribute(.font, range: range)
            addAttribute(.font, value: newFont, range: range)
        }
    }

    @discardableResult
    fileprivate func ub_addAttributes(forLabelType type: UBLabelType, textAlignment: NSTextAlignment = .left, numberOfLines: Int = 0) -> NSMutableAttributedString {
        // check paragraph style
        let textRange = NSRange(location: 0, length: length)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment

        let lineSpacing = type.lineSpacing

        let lineHeightMultiple = (type.font.pointSize / type.font.lineHeight) * lineSpacing
        paragraphStyle.lineSpacing = lineHeightMultiple * type.font.lineHeight - type.font.lineHeight
        paragraphStyle.lineBreakMode = type.lineBreakMode

        // check hyphenation
        if numberOfLines != 1 {
            paragraphStyle.hyphenationFactor = type.hyphenationFactor
        }

        // add attribute for paragraph
        addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: textRange)

        // add attribute for kerning
        if let k = type.letterSpacing {
            addAttribute(NSAttributedString.Key.kern, value: k, range: textRange)
        }

        return self
    }
}
