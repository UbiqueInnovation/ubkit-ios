//
//  MIMEType+Standard.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 22.03.19.
//

import Foundation

// MARK: - Standards

extension UBMIMEType {
    /// MIME Discrete Types
    /// - seeAlso: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
    public enum StandardType: String {
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

extension UBMIMEType {
    /// AAC audio
    public static var aac: UBMIMEType {
        return UBMIMEType(type: .audio, subtype: "aac")
    }

    /// Any kind of binary data
    public static var binary: UBMIMEType {
        return UBMIMEType(type: .application, subtype: "octet-stream")
    }

    /// Windows OS/2 Bitmap Graphics
    public static var bitmap: UBMIMEType {
        return UBMIMEType(type: .image, subtype: "bmp")
    }

    /// Cascading Style Sheets (CSS)
    public static var css: UBMIMEType {
        return UBMIMEType(type: .text, subtype: "css")
    }

    /// Comma-separated values (CSV)
    public static var csv: UBMIMEType {
        return UBMIMEType(type: .text, subtype: "csv")
    }

    /// Form URL Encoded
    public static var formUrlencoded: UBMIMEType {
        return UBMIMEType(type: .application, subtype: "x-www-form-urlencoded")
    }

    /// Multipart form data
    public static func multipartFormData(boundary: String) -> UBMIMEType {
        return UBMIMEType(type: .multipart, subtype: "form-data", parameter: Parameter(key: "boundary", value: boundary))
    }

    /// Graphics Interchange Format (GIF)
    public static var gif: UBMIMEType {
        return UBMIMEType(type: .image, subtype: "gif")
    }

    /// HyperText Markup Language (HTML)
    public static var html: UBMIMEType {
        return UBMIMEType(type: .text, subtype: "html")
    }

    /// JPEG images
    public static var jpeg: UBMIMEType {
        return UBMIMEType(type: .image, subtype: "jpeg")
    }

    /// JavaScript
    public static var javascript: UBMIMEType {
        return UBMIMEType(type: .text, subtype: "javascript")
    }

    /// JSON format
    public static func json(encoding: String.Encoding = .utf8) -> UBMIMEType {
        return UBMIMEType(type: .application, subtype: "json", parameter: Parameter(charsetForEncoding: encoding))
    }

    /// Musical Instrument Digital Interface (MIDI)
    public static var midi: UBMIMEType {
        return UBMIMEType(type: .audio, subtype: "midi")
    }

    /// MP3 audio
    public static var mp3: UBMIMEType {
        return UBMIMEType(type: .audio, subtype: "mpeg")
    }

    /// MPEG Video
    public static var mpeg: UBMIMEType {
        return UBMIMEType(type: .video, subtype: "mpeg")
    }

    /// Portable Network Graphics
    public static var png: UBMIMEType {
        return UBMIMEType(type: .image, subtype: "png")
    }

    /// Adobe Portable Document Format (PDF)
    public static var pdf: UBMIMEType {
        return UBMIMEType(type: .application, subtype: "pdf")
    }

    /// Rich Text Format (RTF)
    public static var rtf: UBMIMEType {
        return UBMIMEType(type: .application, subtype: "rtf")
    }

    /// Scalable Vector Graphics (SVG)
    public static var svg: UBMIMEType {
        return UBMIMEType(type: .image, subtype: "image/svg+xml")
    }

    /// TrueType Font
    public static var ttf: UBMIMEType {
        return UBMIMEType(type: .font, subtype: "ttf")
    }

    /// Text
    ///
    /// - Parameter charset: The charset of the text
    /// - Returns: A Text plain MIME
    public static func text(encoding: String.Encoding? = nil) -> UBMIMEType {
        let parameter: Parameter?
        if let encoding = encoding {
            parameter = Parameter(charsetForEncoding: encoding)
        } else {
            parameter = nil
        }
        return UBMIMEType(type: .text, subtype: "plain", parameter: parameter)
    }

    /// Waveform Audio Format
    public static var wav: UBMIMEType {
        return UBMIMEType(type: .audio, subtype: "wav")
    }

    /// Web Open Font Format (WOFF)
    public static var woff: UBMIMEType {
        return UBMIMEType(type: .font, subtype: "woff")
    }

    /// Web Open Font Format (WOFF2)
    public static var woff2: UBMIMEType {
        return UBMIMEType(type: .font, subtype: "woff2")
    }

    /// XML
    public static var xmlApplication: UBMIMEType {
        return UBMIMEType(type: .application, subtype: "xml")
    }

    /// XML
    public static var xmlText: UBMIMEType {
        return UBMIMEType(type: .text, subtype: "xml")
    }

    /// ZIP archive
    public static var zip: UBMIMEType {
        return UBMIMEType(type: .application, subtype: "zip")
    }
}
