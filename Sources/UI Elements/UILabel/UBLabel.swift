//
//  UBLabel.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - UBLabelType Protocol

public protocol UBLabelType
{
    var font : UIFont { get }
    var textColor : UIColor { get }
    var lineSpacing : CGFloat { get }
    var letterSpacing : CGFloat? { get }

    var isUppercased : Bool { get }

    var hyphenationFactor : Float { get }
    var lineBreakMode : NSLineBreakMode { get }
}

// MARK: - UBLabel

public class UBLabel<T: UBLabelType> : UILabel
{
    private let type : T

    private var lineSpacing : CGFloat = 1.0
    private var kerningValue : CGFloat?
    private var hyphenated: Bool = true

    /// Simple way to initialize Label with T and optional textColor to override standard color of type. Standard multiline and left-aligned.
    public init(_ type: T, textColor : UIColor? = nil, numberOfLines : Int = 0, textAlignment : NSTextAlignment = .left)
    {
        self.type = type

        super.init(frame: .zero)

        self.font = self.type.font
        self.textColor = textColor == nil ? self.type.textColor : textColor
        self.textAlignment = textAlignment
        self.lineSpacing = self.type.lineSpacing
        self.kerningValue = self.type.letterSpacing
        self.numberOfLines = numberOfLines
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var text: String?
    {
        didSet { self.update() }
    }

    public var isHtmlContent: Bool = false
    {
        didSet { self.update() }
    }

    public override var numberOfLines: Int
    {
        didSet
        {
            if numberOfLines == 1
            {
                // why would you hyphenate?
                // (also fixes alignment issues)
                hyphenated = false
                lineSpacing = 1.0
            }
            else
            {
                hyphenated = true
                lineSpacing = self.type.lineSpacing
            }
        }
    }

    /// :nodoc:
    private func update()
    {
        guard var textContent = self.text else
        {
            self.attributedText = nil
            return
        }

        // uppercase the text if type is uppercased
        if self.type.isUppercased
        {
            textContent = textContent.uppercased()
        }

        // create attributed string
        let textString: NSMutableAttributedString

        // check html
        do
        {
            var text = textContent

            if self.isHtmlContent
            {
                text = textContent + "<style>body{font-family: '\(font.fontName)'; font-size:\(self.font.pointSize)px;}</style>"
            }

            let options: [NSAttributedString.DocumentReadingOptionKey : Any] = [
                .documentType: self.isHtmlContent ? NSAttributedString.DocumentType.html : NSAttributedString.DocumentType.plain,
                .characterEncoding: String.Encoding.utf8.rawValue,
                .defaultAttributes: [:]]

            textString = try NSMutableAttributedString(data: text.data(using: .utf8)!, options: options, documentAttributes: nil)
        }
        catch
        {
            textString = NSMutableAttributedString(string: textContent, attributes: [:])
        }

        // check paragraph style
        let textRange = NSRange(location: 0, length: textString.length)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = self.textAlignment

        let lineHeightMultiple = (self.font.pointSize / self.font.lineHeight) * self.lineSpacing
        paragraphStyle.lineSpacing = lineHeightMultiple * self.font.lineHeight - self.font.lineHeight
        paragraphStyle.lineBreakMode = self.type.lineBreakMode

        // check hyphenation
        if hyphenated
        {
            paragraphStyle.hyphenationFactor = self.type.hyphenationFactor
        }

        // add attribute for paragraph
        textString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range: textRange)

        // add attribute for kerning
        if let k = self.kerningValue
        {
            textString.addAttribute(NSAttributedString.Key.kern, value: k, range: textRange)
        }

        // set attributed text
        self.attributedText = textString
    }
}

