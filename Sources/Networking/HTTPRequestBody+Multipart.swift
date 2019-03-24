//
//  HTTPRequestBody+Multipart.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 23.03.19.
//

import Foundation

/// A multipart body
public struct HTTPRequestBodyMultipart: HTTPRequestBodyConvertible {
    /// The encoding to use for strings
    public var encoding: String.Encoding
    /// The parameters to send
    public var parameters: [Parameter]
    /// The payloads to send
    public var payloads: [Payload]
    /// The boundary to be used for segmentation
    public let boundary: String

    /// Initializes a multipart request body
    ///
    /// - Parameters:
    ///   - parameters: The parameters describing the data
    ///   - payloads: The payloads containing the data
    ///   - encoding: The encoding to use for strings
    public init(parameters: [Parameter] = [], payloads: [Payload] = [], encoding: String.Encoding = .utf8) {
        self.parameters = parameters
        self.payloads = payloads
        self.encoding = encoding
        boundary = "Boundary-\(UUID().uuidString)"
    }

    /// :nodoc:
    public func httpRequestBody() throws -> HTTPRequestBody {
        guard parameters.isEmpty == false || payloads.isEmpty == false else {
            throw NetworkingError.couldNotEncodeBody
        }

        var data: Data = Data()

        guard let boundaryPrefix = "--\(boundary)\r\n".data(using: encoding) else {
            throw NetworkingError.couldNotEncodeBody
        }

        for parameter in parameters {
            guard let header = "Content-Disposition: form-data; name=\"\(parameter.name)\"\r\n\r\n".data(using: encoding),
                let value = "\(parameter.value)\r\n".data(using: encoding) else {
                throw NetworkingError.couldNotEncodeBody
            }
            data.append(boundaryPrefix)
            data.append(header)
            data.append(value)
        }

        for payload in payloads {
            guard let header = "Content-Disposition: form-data; name=\"\(payload.name)\"; filename=\"\(payload.fileName)\"\r\n".data(using: encoding), let contentType = "Content-Type: \(payload.mimeType.stringValue)\r\n\r\n".data(using: encoding), let ending = "\r\n".data(using: encoding) else {
                throw NetworkingError.couldNotEncodeBody
            }
            data.append(boundaryPrefix)
            data.append(header)
            data.append(contentType)
            data.append(payload.data)
            data.append(ending)
        }

        let endingString = "--" + boundary + "--\r\n"
        guard let ending = endingString.data(using: encoding) else {
            throw NetworkingError.couldNotEncodeBody
        }
        data.append(ending)

        return HTTPRequestBody(data: data, mimeType: .multipartFormData(boundary: boundary))
    }
}

// MARK: - Parts

extension HTTPRequestBodyMultipart {
    /// Multipart parameter
    public struct Parameter {
        /// Name
        let name: String
        /// Value
        let value: String

        /// Initializes a multipart parameter
        ///
        /// - Parameters:
        ///   - name: Name of the parameter
        ///   - value: Value of the parameter
        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }

    /// Multipart payload
    public struct Payload {
        /// Name
        let name: String
        /// File name
        let fileName: String
        /// Data
        let data: Data
        /// MIME type
        let mimeType: MIMEType

        /// Initializes a multipart payload
        ///
        /// - Parameters:
        ///   - name: The name of payload
        ///   - fileName: The file name of payload
        ///   - data: The data of payload
        ///   - mimeType: The MIME type of the data
        public init(name: String, fileName: String, data: Data, mimeType: MIMEType) {
            self.name = name
            self.fileName = fileName
            self.data = data
            self.mimeType = mimeType
        }

        /// Initializes a multipart payload
        ///
        /// - Parameters:
        ///   - name: The name of payload
        ///   - fileName: The file name of payload
        ///   - body: A request body convertible object to serve as a payload
        /// - Throws: Errors in case the data could not be extracted from the body
        public init(name: String, fileName: String, body: HTTPRequestBodyConvertible) throws {
            let b = try body.httpRequestBody()
            self.init(name: name, fileName: fileName, data: b.data, mimeType: b.mimeType)
        }
    }
}
