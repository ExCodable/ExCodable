//
//  ExCodableRuntime.swift
//  ExCodable
//
//  Created by Míng on 2026-10-22.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import Foundation

/// Calls used by code that `@ExCodable` generates.
public enum ExCodableRuntime {
    
    public static func converter(of type: Any.Type) -> (any ExCodableDecodingTypeConverter.Type)? {
        type as? any ExCodableDecodingTypeConverter.Type
    }
    
    public static func keyString(_ key: String) -> String { key }
    public static func keyString(_ key: any CodingKey) -> String { key.stringValue }
    
    public static func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from decoder: Decoder,
        keys: [String],
        nonnull: Bool,
        throws: Bool,
        converter: (any ExCodableDecodingTypeConverter.Type)?,
        customDecode: ((Decoder) throws -> T?)? = nil
    ) throws -> T? {
        if let customDecode {
            return try customDecode(decoder)
        }
        return try decoder.decode(keys, as: type, nonnull: nonnull, throws: `throws`, converter: converter)
    }
    
    public static func decode<T: Decodable & RawRepresentable>(
        _ type: T.Type = T.self,
        from decoder: Decoder,
        keys: [String],
        nonnull: Bool,
        throws: Bool,
        converter: (any ExCodableDecodingTypeConverter.Type)?,
        customDecode: ((Decoder) throws -> T?)? = nil
    ) throws -> T? where T.RawValue: Decodable {
        if let customDecode {
            return try customDecode(decoder)
        }
        guard let rawValue = try decoder.decode(keys, as: T.RawValue.self, nonnull: nonnull, throws: `throws`, converter: converter),
              let value = T(rawValue: rawValue) else { return nil }
        return value
    }
    
    public static func decode<T: Decodable & RawRepresentable>(
        _ type: T?.Type = T?.self,
        from decoder: Decoder,
        keys: [String],
        nonnull: Bool,
        throws: Bool,
        converter: (any ExCodableDecodingTypeConverter.Type)?,
        customDecode: ((Decoder) throws -> T??)? = nil
    ) throws -> T?? where T.RawValue: Decodable {
        if let customDecode {
            return try customDecode(decoder)
        }
        guard let rawValue = try decoder.decode(keys, as: T.RawValue.self, nonnull: nonnull, throws: `throws`, converter: converter) else { return nil }
        return T(rawValue: rawValue)
    }
    
    public static func encode<T: Encodable>(
        _ value: T,
        to encoder: Encoder,
        for key: String,
        nonnull: Bool,
        throws: Bool,
        customEncode: ((Encoder, T) throws -> Void)? = nil
    ) throws {
        let deepWrapped = if let optional = value as? OptionalProtocol {
            optional.wrapped
        }
        else {
            value
        }
        // !!!: NOT `if let deepWrapped, nonnull`
        if deepWrapped != nil || nonnull {
            if let customEncode {
                try customEncode(encoder, value)
            }
            else {
                try encoder.encode(value, for: key, nonnull: nonnull, throws: `throws`)
            }
        }
        else {
            encoder.ensureKeyedContainer()
        }
    }
    
    /// Opens the root keyed container so an empty `encode(to:)` becomes `{}`.
    public static func openKeyedContainer(_ encoder: Encoder) {
        encoder.ensureKeyedContainer()
    }
}
