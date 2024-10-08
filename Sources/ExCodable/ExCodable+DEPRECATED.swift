//
//  ExCodable+DEPRECATED.swift
//  ExCodable
//
//  Created by Míng on 2021-07-01.
//  Copyright (c) 2021 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import Foundation

// TODO: REMOVE

/// Migration ExCodable from 0.x to 1.x:
/// 
/// DEPRECATED:
/// 
/// - Replace `ExCodable` with `ExCodableDEPRECATED`.
/// 
/// SUGGESTED:
/// 
/// - Replace `ExCodable` with `ExAutoCodable`.
/// - Remove `static` properties `keyMapping`.
/// - Remove initializer `init(from decoder: Decoder) throws`.
/// - Use `@ExCodable("<key>", "<alt-key>")`.
/// 

// MARK: adaptor

@available(*, deprecated)
fileprivate extension Encoder {
    func _encode<T: Encodable>(_ value: T?, for stringKey: String, nonnull: Bool = false, throws: Bool = false) throws {
        try encode(value, for: stringKey, nonnull: nonnull, throws: `throws`)
    }
    func _encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K, nonnull: Bool = false, throws: Bool = false) throws {
        try encode(value, for: codingKey, nonnull: nonnull, throws: `throws`)
    }
}

@available(*, deprecated)
fileprivate extension Decoder {
    func _decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false, converter: (any ExCodableDecodingTypeConverter.Type)? = nil) throws -> T? {
        return try decode(stringKeys, as: type, nonnull: nonnull, throws: `throws`, converter: converter)
    }
    func _decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false, converter: (any ExCodableDecodingTypeConverter.Type)? = nil) throws -> T? {
        try decode(codingKeys, as: type, nonnull: nonnull, throws: `throws`, converter: converter)
    }
}

// MARK: - keyMapping

@available(*, deprecated, message: "Use property wrapper `@ExCodable` instead.")
public protocol ExCodableDEPRECATED: Codable {
    associatedtype Root = Self where Root: ExCodableDEPRECATED
    static var keyMapping: [KeyMap<Root>] { get }
}

@available(*, deprecated)
public extension ExCodableDEPRECATED where Root == Self {
    // default implementation of ExCodableDEPRECATED
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
public extension ExCodableDEPRECATED {
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

@available(*, deprecated, message: "Use property wrapper `@ExCodable` instead.")
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
            try encoder._encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder._decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    convenience init<Value: Codable, Key: CodingKey>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: Key ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder._encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder._decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    convenience init<Value: Codable>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: String ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder._encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: nil, decodeReference: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder._decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        })
    }
    convenience init<Value: Codable, Key: CodingKey>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: Key ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder._encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: nil, decodeReference: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder._decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        })
    }
}

// MARK: -

@available(*, deprecated)
public extension ExCodableDEPRECATED {
    @available(*, deprecated)
    func encode(with keyMapping: [KeyMap<Self>], using encoder: Encoder) {
        try? encode(to: encoder, with: keyMapping)
    }
    @available(*, deprecated)
    mutating func decode(with keyMapping: [KeyMap<Self>], using decoder: Decoder) {
        try? decode(from: decoder, with: keyMapping)
    }
    @available(*, deprecated)
    func decodeReference(with keyMapping: [KeyMap<Self>], using decoder: Decoder) {
        try? decodeReference(from: decoder, with: keyMapping)
    }
}

@available(*, deprecated)
public protocol KeyedDecodingContainerCustomTypeConversion: ExCodableDecodingTypeConverter {
    static func decodeForTypeConversion<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T?
}
@available(*, deprecated)
public extension KeyedDecodingContainerCustomTypeConversion {
    static func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T? {
        return decodeForTypeConversion(container, codingKey: codingKey, as: type)
    }
}
