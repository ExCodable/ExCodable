//
//  ExCodable.swift
//  ExCodable
//
//  Created by Mr. Ming on 2021-07-01.
//  Copyright (c) 2021 Mr. Ming <minglq.9@gmail.com>. Released under the MIT license.
//

import Foundation

// MARK: - keyMapping

@available(*, deprecated, message: "use `@ExCodable` property wrapper instead")
public protocol ExCodableProtocol: Codable {
    associatedtype Root = Self where Root: ExCodableProtocol
    static var keyMapping: [KeyMap<Root>] { get }
}

@available(*, deprecated)
public extension ExCodableProtocol where Root == Self {
    
    // default implementation of ExCodableProtocol
    static var keyMapping: [KeyMap<Root>] { [] }
    
    // default implementation of Encodable
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.keyMapping)
        try encode(to: encoder, nonnull: false, throws: false)
    }
    
    func decode(from decoder: Decoder) throws {
        try decode(from: decoder, nonnull: false, throws: false)
    }
}

@available(*, deprecated)
public extension ExCodableProtocol {
    func encode(to encoder: Encoder, with keyMapping: [KeyMap<Self>], nonnull: Bool = false, throws: Bool = false) throws {
        try keyMapping.forEach { try $0.encode(self, encoder, nonnull, `throws`) }
    }
    mutating func decode(from decoder: Decoder, with keyMapping: [KeyMap<Self>], nonnull: Bool = false, throws: Bool = false) throws {
        try keyMapping.forEach { try $0.decode?(&self, decoder, nonnull, `throws`) }
    }
    func decodeReference(from decoder: Decoder, with keyMapping: [KeyMap<Self>], nonnull: Bool = false, throws: Bool = false) throws {
        try keyMapping.forEach { try $0.decodeReference?(self, decoder, nonnull, `throws`) }
    }
}

@available(*, deprecated, message: "use `@ExCodable` property wrapper instead")
public final class KeyMap<Root: Codable> {
    fileprivate let encode: (_ root: Root, _ encoder: Encoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void
    fileprivate let decode: ((_ root: inout Root, _ decoder: Decoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void)?
    fileprivate let decodeReference: ((_ root: Root, _ decoder: Decoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void)?
    private init(encode: @escaping (_ root: Root, _ encoder: Encoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void,
                 decode: ((_ root: inout Root, _ decoder: Decoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void)?,
                 decodeReference: ((_ root: Root, _ decoder: Decoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void)?) {
        (self.encode, self.decode, self.decodeReference) = (encode, decode, decodeReference)
    }
}

@available(*, deprecated)
public extension KeyMap {
    convenience init<Value: Codable>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: String ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    convenience init<Value: Codable, Key: CodingKey>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: Key ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    convenience init<Value: Codable>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: String ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: nil, decodeReference: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        })
    }
    convenience init<Value: Codable, Key: CodingKey>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: Key ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: nil, decodeReference: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        })
    }
}

// MARK: -

@available(*, deprecated)
public extension ExCodableProtocol {
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
