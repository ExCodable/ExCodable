//
//  ExCodableRuntime.swift
//  ExCodable
//
//  Created by Míng on 2026-10-22.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import Foundation

/// Calls used by code that `@ExCodable` generates. Do not call these directly: they may change without notice.
///
/// The members are `public` only because the generated code is compiled in the user's module.
/// `@_spi` cannot be used here, since it would require every file that uses `@ExCodable` to carry
/// `@_spi(...) import ExCodable`. The leading underscore and `@_documentation` mark them as internal.
@_documentation(visibility: private)
public enum ExCodableRuntime {
    
    public static func _converter(of type: Any.Type) -> (any ExCodableDecodingTypeConverter.Type)? {
        type as? any ExCodableDecodingTypeConverter.Type
    }
    
    public static func _keyString(_ key: String) -> String { key }
    public static func _keyString(_ key: any CodingKey) -> String { key.stringValue }
    
    public static func _decode<T: Decodable>(
        _ type: T.Type = T.self,
        from decoder: Decoder,
        keys: [String],
        optional: Bool,
        strictType: Bool,
        converter: (any ExCodableDecodingTypeConverter.Type)?,
        customDecode: ((Decoder) throws -> T?)? = nil
    ) throws -> T? {
        if let customDecode {
            return try customDecode(decoder)
        }
        return try decoder.decode(keys, as: type, optional: optional, strictType: `strictType`, converter: converter)
    }
    
    public static func _decode<T: Decodable & RawRepresentable>(
        _ type: T.Type = T.self,
        from decoder: Decoder,
        keys: [String],
        optional: Bool,
        strictType: Bool,
        converter: (any ExCodableDecodingTypeConverter.Type)?,
        customDecode: ((Decoder) throws -> T?)? = nil
    ) throws -> T? where T.RawValue: Decodable {
        if let customDecode {
            return try customDecode(decoder)
        }
        if let value = try? decoder.decode(keys, as: T.self, optional: true, strictType: false, converter: converter) {
            return value
        }
        if let rawValue = try decoder.decode(keys, as: T.RawValue.self, optional: optional, strictType: `strictType`, converter: converter) {
            return T(rawValue: rawValue)
        }
        return nil
    }
    
    public static func _decode<T: Decodable & RawRepresentable>(
        _ type: T?.Type = T?.self,
        from decoder: Decoder,
        keys: [String],
        optional: Bool,
        strictType: Bool,
        converter: (any ExCodableDecodingTypeConverter.Type)?,
        customDecode: ((Decoder) throws -> T??)? = nil
    ) throws -> T?? where T.RawValue: Decodable {
        if let customDecode {
            return try customDecode(decoder)
        }
        if let value = try? decoder.decode(keys, as: T.self, optional: true, strictType: false, converter: converter) {
            return value
        }
        if let rawValue = try decoder.decode(keys, as: T.RawValue.self, optional: optional, strictType: `strictType`, converter: converter) {
            return T(rawValue: rawValue)
        }
        return nil
    }
    
    public static func _encode<T: Encodable>(
        _ value: T,
        to encoder: Encoder,
        for key: String,
        optional: Bool,
        strictType: Bool,
        customEncode: ((Encoder, T) throws -> Void)? = nil
    ) throws {
        let deepWrapped = if let wrapped = value as? OptionalProtocol {
            wrapped.wrapped
        }
        else {
            value
        }
        // !!!: NOT `if let deepWrapped, optional`
        if deepWrapped != nil || !optional {
            if let customEncode {
                try customEncode(encoder, value)
            }
            else {
                try encoder.encode(value, for: key, optional: optional, strictType: `strictType`)
            }
        }
        else {
            encoder.ensureKeyedContainer()
        }
    }
    
    /// Opens the root keyed container so an empty `encode(to:)` becomes `{}`.
    public static func _openKeyedContainer(_ encoder: Encoder) {
        encoder.ensureKeyedContainer()
    }
}
