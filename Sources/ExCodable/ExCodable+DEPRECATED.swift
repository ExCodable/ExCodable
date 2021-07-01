//
//  ExCodable.swift
//  ExCodable
//
//  Created by Mr. Ming on 2021-07-01.
//  Copyright (c) 2021 Mr. Ming <minglq.9@gmail.com>. Released under the MIT license.
//

import Foundation

public extension ExCodable {
    @available(*, deprecated, renamed: "encode(to:with:nonnull:throws:)")
    func encode(with keyMapping: [KeyMap<Self>], using encoder: Encoder) {
        try? encode(to: encoder, with: keyMapping)
    }
    @available(*, deprecated, renamed: "decode(from:with:nonnull:throws:)")
    mutating func decode(with keyMapping: [KeyMap<Self>], using decoder: Decoder) {
        try? decode(from: decoder, with: keyMapping)
    }
    @available(*, deprecated, renamed: "decodeReference(from:with:nonnull:throws:)")
    func decodeReference(with keyMapping: [KeyMap<Self>], using decoder: Decoder) {
        try? decodeReference(from: decoder, with: keyMapping)
    }
}

@available(*, deprecated, renamed: "append(decodingTypeConverter:)")
public protocol KeyedDecodingContainerCustomTypeConversion: ExCodableDecodingTypeConverter {
    func decodeForTypeConversion<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T?
}
@available(*, deprecated)
public extension KeyedDecodingContainerCustomTypeConversion {
    func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) throws -> T? {
        return decodeForTypeConversion(container, codingKey: codingKey, as: type)
    }
}
