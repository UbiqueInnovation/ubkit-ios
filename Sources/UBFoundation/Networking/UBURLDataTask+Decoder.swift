//
//  UBURLDataTask+Decoder.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 21.03.19.
//
#if os(iOS) || os(tvOS) || os(watchOS)

import Foundation

/// An object that can decode data into the desired type
open class UBURLDataTaskDecoder<T> {
    /// The logic for data decoding
    public typealias LogicBlock = (Data, HTTPURLResponse) throws -> T

    /// :nodoc:
    private let logic: LogicBlock

    /// Initalizes a decoder with a logic
    ///
    /// - Parameter logic: The logic to decode
    public init(withLogic logic: @escaping LogicBlock) {
        self.logic = logic
    }

    /// Attempt to decode the data
    ///
    /// - Parameters:
    ///   - data: The data to decode
    ///   - response: The HTTP URL Response associated with the data
    /// - Returns: The decoded object in case of success
    /// - Throws: If the decoding encountered an issue
    public final func decode(data: Data, response: HTTPURLResponse) throws -> T {
        try logic(data, response)
    }
}

/// A string decoder
public class UBHTTPStringDecoder: UBURLDataTaskDecoder<String> {
    /// Initializes the decoder
    ///
    /// - Parameter encoding: The string encoding
    public init(encoding: String.Encoding = .utf8) {
        super.init { data, _ -> String in
            guard let string = String(data: data, encoding: encoding) else {
                throw UBInternalNetworkingError.couldNotDecodeBody
            }
            return string
        }
    }
}

/// A JSON Decoder
public class UBHTTPJSONDecoder<T: Decodable>: UBURLDataTaskDecoder<T> {
    /// Initializes the decoder
    ///
    /// - Parameters:
    ///   - dateDecodingStrategy: A strategy to decode dates
    ///   - dataDecodingStrategy: A strategy to decode data
    public convenience init(dateDecodingStrategy: JSONDecoder.DateDecodingStrategy, dataDecodingStrategy: JSONDecoder.DataDecodingStrategy) {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
        jsonDecoder.dataDecodingStrategy = dataDecodingStrategy
        self.init(decoder: jsonDecoder)
    }

    /// Initializes the decoder
    ///
    /// - Parameter decoder: A JSON decoder
    public init(decoder: JSONDecoder = JSONDecoder()) {
        super.init { data, _ -> T in
            try decoder.decode(T.self, from: data)
        }
    }
}
#endif
