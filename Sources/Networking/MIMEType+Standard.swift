//
//  MIMEType+Standard.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 22.03.19.
//

import Foundation

// MARK: - Standards

extension MIMEType {
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

extension MIMEType {
    /// AAC audio
    public static var aac: MIMEType {
        return MIMEType(type: .audio, subtype: "aac")
    }

    /// Any kind of binary data
    public static var binary: MIMEType {
        return MIMEType(type: .application, subtype: "octet-stream")
    }

    /// Windows OS/2 Bitmap Graphics
    public static var bitmap: MIMEType {
        return MIMEType(type: .image, subtype: "bmp")
    }

    /// Cascading Style Sheets (CSS)
    public static var css: MIMEType {
        return MIMEType(type: .text, subtype: "css")
    }

    /// Comma-separated values (CSV)
    public static var csv: MIMEType {
        return MIMEType(type: .text, subtype: "csv")
    }

    /// Form URL Encoded
    public static var formUrlencoded: MIMEType {
        return MIMEType(type: .application, subtype: "x-www-form-urlencoded")
    }

    /// Multipart form data
    public static func multipartFormData(boundary: String) -> MIMEType {
        return MIMEType(type: .multipart, subtype: "form-data", parameter: Parameter(key: "boundary", value: boundary))
    }

    /// Graphics Interchange Format (GIF)
    public static var gif: MIMEType {
        return MIMEType(type: .image, subtype: "gif")
    }

    /// HyperText Markup Language (HTML)
    public static var html: MIMEType {
        return MIMEType(type: .text, subtype: "html")
    }

    /// JPEG images
    public static var jpeg: MIMEType {
        return MIMEType(type: .image, subtype: "jpeg")
    }

    /// JavaScript
    public static var javascript: MIMEType {
        return MIMEType(type: .text, subtype: "javascript")
    }

    /// JSON format
    public static func json(encoding: String.Encoding = .utf8) -> MIMEType {
        return MIMEType(type: .application, subtype: "json", parameter: Parameter(charsetForEncoding: encoding))
    }

    /// Musical Instrument Digital Interface (MIDI)
    public static var midi: MIMEType {
        return MIMEType(type: .audio, subtype: "midi")
    }

    /// MP3 audio
    public static var mp3: MIMEType {
        return MIMEType(type: .audio, subtype: "mpeg")
    }

    /// MPEG Video
    public static var mpeg: MIMEType {
        return MIMEType(type: .video, subtype: "mpeg")
    }

    /// Portable Network Graphics
    public static var png: MIMEType {
        return MIMEType(type: .image, subtype: "png")
    }

    /// Adobe Portable Document Format (PDF)
    public static var pdf: MIMEType {
        return MIMEType(type: .application, subtype: "pdf")
    }

    /// Rich Text Format (RTF)
    public static var rtf: MIMEType {
        return MIMEType(type: .application, subtype: "rtf")
    }

    /// Scalable Vector Graphics (SVG)
    public static var svg: MIMEType {
        return MIMEType(type: .image, subtype: "image/svg+xml")
    }

    /// TrueType Font
    public static var ttf: MIMEType {
        return MIMEType(type: .font, subtype: "ttf")
    }

    /// Text
    ///
    /// - Parameter charset: The charset of the text
    /// - Returns: A Text plain MIME
    public static func text(encoding: String.Encoding? = nil) -> MIMEType {
        let parameter: Parameter?
        if let encoding = encoding {
            parameter = Parameter(charsetForEncoding: encoding)
        } else {
            parameter = nil
        }
        return MIMEType(type: .text, subtype: "plain", parameter: parameter)
    }

    /// Waveform Audio Format
    public static var wav: MIMEType {
        return MIMEType(type: .audio, subtype: "wav")
    }

    /// Web Open Font Format (WOFF)
    public static var woff: MIMEType {
        return MIMEType(type: .font, subtype: "woff")
    }

    /// Web Open Font Format (WOFF2)
    public static var woff2: MIMEType {
        return MIMEType(type: .font, subtype: "woff2")
    }

    /// XML
    public static var xmlApplication: MIMEType {
        return MIMEType(type: .application, subtype: "xml")
    }

    /// XML
    public static var xmlText: MIMEType {
        return MIMEType(type: .text, subtype: "xml")
    }

    /// ZIP archive
    public static var zip: MIMEType {
        return MIMEType(type: .application, subtype: "zip")
    }
}
