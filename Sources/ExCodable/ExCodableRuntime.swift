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
/// The leading underscore and `@_documentation` mark them as private.
@_documentation(visibility: private)
public enum ExCodableRuntime {
    
    public static func _converter(of type: Any.Type) -> (any ExCodableDecodingTypeConverter.Type)? {
        type as? any ExCodableDecodingTypeConverter.Type
    }
    
    public static func _keyString(_ key: String) -> String { key }
    public static func _keyString(_ key: any CodingKey) -> String { key.stringValue }
    
    private static func __decode<T: Decodable>(_ type: T.Type = T.self, from decoder: Decoder, keys: [String], optional: Bool, strictType: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?, customDecode: ((Decoder) throws -> T?)? = nil) throws -> T? {
        guard let customDecode else {
            return try decoder.decode(keys, as: type, optional: optional, strictType: strictType, converter: converter)
        }
        if let value = try customDecode(decoder) {
            return value
        }
        if !optional { // !!!: only throws for custom decode
            let description = "Value not found in custom decode closure with keys \(keys.map { "\"\($0)\"" }.joined(separator: ", "))."
            throw DecodingError.valueNotFound(T.self, .init(codingPath: decoder.codingPath, debugDescription: description))
        }
        return nil
    }
    
    public static func _decode<T: Decodable>(_ type: T.Type = T.self, from decoder: Decoder, keys: [String], optional: Bool, strictType: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?, customDecode: ((Decoder) throws -> T?)? = nil) throws -> T? {
        return try __decode(T.self, from: decoder, keys: keys, optional: optional, strictType: strictType, converter: converter, customDecode: customDecode)
    }
    
    public static func _decode<T: Decodable & RawRepresentable>(_ type: T.Type = T.self, from decoder: Decoder, keys: [String], optional: Bool, strictType: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?, customDecode: ((Decoder) throws -> T?)? = nil) throws -> T? where T.RawValue: Decodable {
        var prevError: Error?
        
        do { if let value = try __decode(T.self, from: decoder, keys: keys, optional: optional, strictType: strictType, converter: converter, customDecode: customDecode) {
            return value
        }}
        catch { prevError = prevError ?? error }
        
        do {
            if customDecode == nil,
               let rawValue = try __decode(T.RawValue.self, from: decoder, keys: keys, optional: optional, strictType: strictType, converter: converter/* NO `customDecode:` here! */),
               let value = T(rawValue: rawValue) {
                return value
            }
        }
        catch { prevError = prevError ?? error }
        
        if let prevError { throw prevError }
        return nil
    }
    
    public static func _decode<T: Decodable & RawRepresentable>(_ type: T?.Type = T?.self, from decoder: Decoder, keys: [String], optional: Bool, strictType: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?, customDecode: ((Decoder) throws -> T??)? = nil) throws -> T?? where T.RawValue: Decodable {
        return try _decode(T.self, from: decoder, keys: keys, optional: optional, strictType: strictType, converter: converter, customDecode: customDecode.map({ customDecode in
            return { (decoder) throws -> T? in try customDecode(decoder) ?? nil }
        }))
    }
    
    public static func _encode<T: Encodable>(_ value: T, to encoder: Encoder, for key: String, optional: Bool, strictType: Bool, customEncode: ((Encoder, T) throws -> Void)? = nil) throws {
        let deepWrapped = if let wrapped = value as? OptionalProtocol { wrapped.wrapped } else { value }
        
        guard deepWrapped != nil || optional else {
            let desc = "Expected to encode a required \(T?.wrappedType) but found null value instead."
            throw EncodingError.invalidValue(value as Any, .init(codingPath: encoder.codingPath, debugDescription: desc))
        }
        
        if let customEncode {
            try customEncode(encoder, value)
        }
        else if deepWrapped != nil || !optional {
            try encoder.encode(value, for: key, optional: optional, strictType: strictType)
        }
        else {
            encoder.encodeEmpty()
        }
    }
    
    public static func _encodeEmpty(_ encoder: Encoder) {
        encoder.encodeEmpty()
    }
}
