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

    public override var text: String? {
        didSet { update() }
    }

    public var isHtmlContent: Bool = false {
        didSet { update() }
    }

    /// :nodoc:
    private func update() {
        guard var textContent = text else {
            attributedText = nil
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
            var text = textContent

            if isHtmlContent {
                text = textContent + "<style>body{font-family: '\(font.fontName)'; font-size:\(font.pointSize)px;}</style>"
            }

            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: isHtmlContent ? NSAttributedString.DocumentType.html : NSAttributedString.DocumentType.plain,
                .characterEncoding: String.Encoding.utf8.rawValue,
                .defaultAttributes: [:]
            ]

            textString = try NSMutableAttributedString(data: text.data(using: .utf8)!, options: options, documentAttributes: nil)
        } catch {
            textString = NSMutableAttributedString(string: textContent, attributes: [:])
        }

        // check paragraph style
        let textRange = NSRange(location: 0, length: textString.length)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment

        let lineSpacing = numberOfLines == 1 ? 1.0 : type.lineSpacing

        let lineHeightMultiple = (font.pointSize / font.lineHeight) * lineSpacing
        paragraphStyle.lineSpacing = lineHeightMultiple * font.lineHeight - font.lineHeight
        paragraphStyle.lineBreakMode = type.lineBreakMode

        // check hyphenation
        if numberOfLines != 1 {
            paragraphStyle.hyphenationFactor = type.hyphenationFactor
        }

        // add attribute for paragraph
        textString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: textRange)

        // add attribute for kerning
        if let k = type.letterSpacing {
            textString.addAttribute(NSAttributedString.Key.kern, value: k, range: textRange)
        }

        // set attributed text
        attributedText = textString
    }
}
