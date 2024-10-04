//
//  MIMEType+Standard.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 22.03.19.
//

import Foundation

// MARK: - Standards

public extension UBMIMEType {
    /// MIME Discrete Types
    /// - seeAlso: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
    enum StandardType: String {
        /// Application
        case application
        /// Audio
        case audio
        /// Font
        case font
        /// Image
        case image
        /// Text
        case text
        /// Video
        case video
        /// Message
        case message
        /// Multipart
        case multipart
    }
}

public extension UBMIMEType {
    /// AAC audio
    static var aac: UBMIMEType {
        UBMIMEType(type: .audio, subtype: "aac")
    }

    /// Any kind of binary data
    static var binary: UBMIMEType {
        UBMIMEType(type: .application, subtype: "octet-stream")
    }

    /// Windows OS/2 Bitmap Graphics
    static var bitmap: UBMIMEType {
        UBMIMEType(type: .image, subtype: "bmp")
    }

    /// Cascading Style Sheets (CSS)
    static var css: UBMIMEType {
        UBMIMEType(type: .text, subtype: "css")
    }

    /// Comma-separated values (CSV)
    static var csv: UBMIMEType {
        UBMIMEType(type: .text, subtype: "csv")
    }

    /// Form URL Encoded
    static var formUrlencoded: UBMIMEType {
        UBMIMEType(type: .application, subtype: "x-www-form-urlencoded")
    }

    /// Multipart form data
    static func multipartFormData(boundary: String) -> UBMIMEType {
        UBMIMEType(type: .multipart, subtype: "form-data", parameter: Parameter(key: "boundary", value: boundary))
    }

    /// Graphics Interchange Format (GIF)
    static var gif: UBMIMEType {
        UBMIMEType(type: .image, subtype: "gif")
    }

    /// HyperText Markup Language (HTML)
    static var html: UBMIMEType {
        UBMIMEType(type: .text, subtype: "html")
    }

    /// JPEG images
    static var jpeg: UBMIMEType {
        UBMIMEType(type: .image, subtype: "jpeg")
    }

    /// JavaScript
    static var javascript: UBMIMEType {
        UBMIMEType(type: .text, subtype: "javascript")
    }

    /// JSON format
    static func json(encoding: String.Encoding = .utf8) -> UBMIMEType {
        UBMIMEType(type: .application, subtype: "json", parameter: Parameter(charsetForEncoding: encoding))
    }

    /// Musical Instrument Digital Interface (MIDI)
    static var midi: UBMIMEType {
        UBMIMEType(type: .audio, subtype: "midi")
    }

    /// MP3 audio
    static var mp3: UBMIMEType {
        UBMIMEType(type: .audio, subtype: "mpeg")
    }

    /// MPEG Video
    static var mpeg: UBMIMEType {
        UBMIMEType(type: .video, subtype: "mpeg")
    }

    /// Portable Network Graphics
    static var png: UBMIMEType {
        UBMIMEType(type: .image, subtype: "png")
    }

    /// Adobe Portable Document Format (PDF)
    static var pdf: UBMIMEType {
        UBMIMEType(type: .application, subtype: "pdf")
    }

    /// Rich Text Format (RTF)
    static var rtf: UBMIMEType {
        UBMIMEType(type: .application, subtype: "rtf")
    }

    /// Scalable Vector Graphics (SVG)
    static var svg: UBMIMEType {
        UBMIMEType(type: .image, subtype: "image/svg+xml")
    }

    /// TrueType Font
    static var ttf: UBMIMEType {
        UBMIMEType(type: .font, subtype: "ttf")
    }

    /// Text
    ///
    /// - Parameter charset: The charset of the text
    /// - Returns: A Text plain MIME
    static func text(encoding: String.Encoding? = nil) -> UBMIMEType {
        let parameter: Parameter? = if let encoding {
            Parameter(charsetForEncoding: encoding)
        } else {
            nil
        }
        return UBMIMEType(type: .text, subtype: "plain", parameter: parameter)
    }

    /// Waveform Audio Format
    static var wav: UBMIMEType {
        UBMIMEType(type: .audio, subtype: "wav")
    }

    /// Web Open Font Format (WOFF)
    static var woff: UBMIMEType {
        UBMIMEType(type: .font, subtype: "woff")
    }

    /// Web Open Font Format (WOFF2)
    static var woff2: UBMIMEType {
        UBMIMEType(type: .font, subtype: "woff2")
    }

    /// XML
    static var xmlApplication: UBMIMEType {
        UBMIMEType(type: .application, subtype: "xml")
    }

    /// XML
    static var xmlText: UBMIMEType {
        UBMIMEType(type: .text, subtype: "xml")
    }

    /// ZIP archive
    static var zip: UBMIMEType {
        UBMIMEType(type: .application, subtype: "zip")
    }
}
