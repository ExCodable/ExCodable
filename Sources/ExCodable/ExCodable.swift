//
//  ExCodable.swift
//  ExCodable
//
//  Created by Míng on 2021-02-10.
//  Copyright (c) 2021 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import Foundation

/// # ExCodable
/// 
/// <#swift#> <#codable#> <#json#> <#model#> <#type-inference#>
/// <#key-mapping#> <#macro#> <#coding-key#> <#subscript#>
/// <#alternative-keys#> <#nested-keys#> <#type-conversions#>
/// 
/// - `ExCodable`: A macro generates `init(from:)` and `encode(to:)`.
/// - `ExCodableKey`: A macro associates JSON keys to properties.
/// - `Encodable` & `Decodable` extensions for encoding/decoding from internal/external.
/// - `Encoder` & `Encoder` extensions for encoding/decoding properties one by one.
/// - Supports alternative keys, nested keys, type conversions, nested optionals and default values.
/// 
/// - seealso: [Usage](https://github.com/ExCodable/ExCodable#usage) from the `README.md`
/// - seealso: `ExCodableTests.swift` from the `Tests`
/// - seealso: [Decoding and overriding](https://www.swiftbysundell.com/articles/property-wrappers-in-swift/#decoding-and-overriding)
/// and [Useful Codable extensions](https://www.swiftbysundell.com/tips/useful-codable-extensions/), by John Sundell.

// MARK: - Encoder & Decoder

public extension Encoder { // , nonnull nonnull: Bool = false, throws throws: Bool = false
    subscript<T: Encodable>(stringKey: String) -> T? { get { return nil }
        nonmutating set { encode(newValue, for: stringKey) }
    }
    subscript<T: Encodable, K: CodingKey>(codingKey: K) -> T? { get { return nil }
        nonmutating set { encode(newValue, for: codingKey) }
    }
}

public extension Decoder { // , nonnull nonnull: Bool = false, throws throws: Bool = false
    subscript<T: Decodable>(stringKeys: [String], converter converter: (any ExCodableDecodingTypeConverter.Type)? = nil) -> T? {
        return decode(stringKeys, as: T.self, converter: converter)
    }
    subscript<T: Decodable>(stringKeys: String ..., converter converter: (any ExCodableDecodingTypeConverter.Type)? = nil) -> T? {
        return decode(stringKeys, as: T.self, converter: converter)
    }
    subscript<T: Decodable, K: CodingKey>(codingKeys: [K], converter converter: (any ExCodableDecodingTypeConverter.Type)? = nil) -> T? {
        return decode(codingKeys, as: T.self, converter: converter)
    }
    subscript<T: Decodable, K: CodingKey>(codingKeys: K ..., converter converter: (any ExCodableDecodingTypeConverter.Type)? = nil) -> T? {
        return decode(codingKeys, as: T.self, converter: converter)
    }
}

public extension Encoder {
    
    func encodeNonnullThrows<T: Encodable>(_ value: T, for stringKey: String) throws {
        try encode(value, for: stringKey, nonnull: true, throws: true)
    }
    func encodeThrows<T: Encodable>(_ value: T?, for stringKey: String) throws {
        try encode(value, for: stringKey, nonnull: false, throws: true)
    }
    func encode<T: Encodable>(_ value: T?, for stringKey: String) {
        try? encode(value, for: stringKey, nonnull: false, throws: false)
    }
    
    internal func encode<T: Encodable>(_ value: T?, for stringKey: String, nonnull: Bool = false, throws: Bool = false) throws {
        
        let keys = stringKey.split(separator: ".").map { ExCodingKey($0) }
        guard keys.count > 1 else {
            try encode(value, for: keys.first ?? ExCodingKey(stringKey), nonnull: nonnull, throws: `throws`)
            return
        }
        
        let codingKey = keys.last!
        var container = self.container(keyedBy: ExCodingKey.self)
        for key in keys.dropLast() {
            container = container.nestedContainer(keyedBy: ExCodingKey.self, forKey: key)
        }
        
        if nonnull {
            if value.wrapped == nil {
                let desc = "Expected to encode nonnull for \(T?.wrappedType) but found null value instead."
                throw EncodingError.invalidValue(value as Any, .init(codingPath: [ExCodingKey(stringKey)], debugDescription: desc))
            }
            try container.encode(value, forKey: codingKey)
        }
        else if `throws` {
            try container.encodeIfPresent(value, forKey: codingKey)
        }
        else {
            try? container.encodeIfPresent(value, forKey: codingKey)
        }
    }
    
    func encodeNonnullThrows<T: Encodable, K: CodingKey>(_ value: T, for codingKey: K) throws {
        try encode(value, for: codingKey, nonnull: true, throws: true)
    }
    func encodeThrows<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K) throws {
        try encode(value, for: codingKey, nonnull: false, throws: true)
    }
    func encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K) {
        try? encode(value, for: codingKey, nonnull: false, throws: false)
    }
    
    internal func encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K, nonnull: Bool = false, throws: Bool = false) throws {
        var container = self.container(keyedBy: K.self)
        if nonnull {
            if value.wrapped == nil {
                let desc = "Expected to encode nonnull for \(T?.wrappedType) but found null value instead."
                throw EncodingError.invalidValue(value as Any, .init(codingPath: [codingKey], debugDescription: desc))
            }
            try container.encode(value, forKey: codingKey)
        }
        else if `throws` {
            try container.encodeIfPresent(value, forKey: codingKey)
        }
        else {
            try? container.encodeIfPresent(value, forKey: codingKey)
        }
    }
    
    /// Gives `JSONEncoder` an empty object when every encoded value is absent.
    internal func ensureKeyedContainer() {
        _ = container(keyedBy: ExCodingKey.self)
    }
}

public extension Decoder {
    
    func decodeNonnullThrows<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T {
        return try decodeNonnullThrows(stringKeys, as: type, converter: converter)
    }
    func decodeNonnullThrows<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T {
        return try decode(stringKeys, as: type, nonnull: true, throws: true, converter: converter)!
    }
    func decodeThrows<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        return try decodeThrows(stringKeys, as: type, converter: converter)
    }
    func decodeThrows<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        return try decode(stringKeys, as: type, nonnull: false, throws: true, converter: converter)
    }
    func decode<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
        return decode(stringKeys, as: type, converter: converter)
    }
    func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
        return try? decode(stringKeys, as: type, nonnull: false, throws: false, converter: converter)
    }
    
    internal func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        return try decode(stringKeys.map { ExCodingKey($0) }, as: type, nonnull: nonnull, throws: `throws`, converter: converter)
    }
    
    func decodeNonnullThrows<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T {
        return try decodeNonnullThrows(codingKeys, as: type, converter: converter)
    }
    func decodeNonnullThrows<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T {
        return try decode(codingKeys, as: type, nonnull: true, throws: true, converter: converter)!
    }
    func decodeThrows<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        return try decodeThrows(codingKeys, as: type, converter: converter)
    }
    func decodeThrows<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        return try decode(codingKeys, as: type, nonnull: false, throws: true, converter: converter)
    }
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
        return decode(codingKeys, as: type, converter: converter)
    }
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
        return try? decode(codingKeys, as: type, nonnull: false, throws: false, converter: converter)
    }
    
    internal func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        if let container = nonnull || `throws` ? try self.container(keyedBy: K.self) : try? self.container(keyedBy: K.self) {
            return try container.decodeForAlternativeKeys(codingKeys, as: type, nonnull: nonnull, throws: `throws`, converter: converter)
        }
        return nil
    }
}

// MARK: - ExCodingKey

fileprivate struct ExCodingKey {
    public let stringValue: String, intValue: Int?
    init<S: LosslessStringConvertible>(_ stringValue: S) { (self.stringValue, self.intValue) = (stringValue as? String ?? String(stringValue), nil) }
}

extension ExCodingKey: CodingKey {
    init?(stringValue: String) { self.init(stringValue) }
    init?(intValue: Int) { self.init(intValue) }
}

// MARK: - KeyedDecodingContainer - alternative-keys + nested-keys + type-conversions

fileprivate extension KeyedDecodingContainer {
    
    func decodeForAlternativeKeys<T: Decodable>(_ codingKeys: [Self.Key], as type: T.Type = T.self, nonnull: Bool, throws: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        
        var caughtError: Error?
        
        do {
            let codingKey = codingKeys.first!
            if let value = try decodeForNestedKeys(codingKey, as: type, nonnull: nonnull, throws: `throws`, converter: converter) {
                return value
            }
        }
        catch { caughtError = error }
        
        do {
            let codingKeys = Array(codingKeys.dropFirst())
            if !codingKeys.isEmpty,
               let value = try decodeForAlternativeKeys(codingKeys, as: type, nonnull: nonnull, throws: `throws`, converter: converter) {
                return value
            }
        }
        catch { caughtError = caughtError ?? error }
        
        if let caughtError { throw caughtError }
        return nil
    }
    
    func decodeForNestedKeys<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, nonnull: Bool, throws: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        
        var caughtError: Error?
        
        do {
            if let value = try decodeForValue(codingKey, as: type, nonnull: nonnull, throws: `throws`, converter: converter) {
                return value
            }
        }
        catch { caughtError = error }
        
        do {
            if let exCodingKey = codingKey as? ExCodingKey, // Self.Key is ExCodingKey.Type
               exCodingKey.intValue == nil {
                let keys = exCodingKey.stringValue.split(separator: ".").map { ExCodingKey($0) }
                if keys.count > 1,
                   let codingKey = keys.last,
                   let container = nestedContainer(with: keys.dropLast()),
                   let value = try container.decodeForNestedKeys(codingKey as! Self.Key, as: type, nonnull: nonnull, throws: `throws`, converter: converter) {
                    return value
                }
            }
        }
        catch { caughtError = caughtError ?? error }
        
        if let caughtError { throw caughtError }
        return nil
    }
    
    private func nestedContainer(with keys: [ExCodingKey]) -> Self? {
        var container: Self? = self
        for key in keys {
            container = try? container?.nestedContainer(keyedBy: Self.Key.self, forKey: key as! Self.Key)
            if container == nil { return nil }
        }
        return container
    }
    
    func decodeForValue<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, nonnull: Bool, throws: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        
        // JSON null is the same absence as a missing key.
        if contains(codingKey), try decodeNil(forKey: codingKey) {
            if nonnull {
                let description = "No value associated with key \(codingKey) (\"\(codingKey.stringValue)\")."
                throw DecodingError.keyNotFound(codingKey, .init(codingPath: codingPath, debugDescription: description))
            }
            return nil
        }
        
        var caughtError: Error?
        do {
            if nonnull {
                let value = try decode(type, forKey: codingKey)
                if let optional = value as? OptionalProtocol, optional.wrapped == nil {
                    let description = "No value associated with key \(codingKey) (\"\(codingKey.stringValue)\")."
                    throw DecodingError.keyNotFound(codingKey, .init(codingPath: codingPath, debugDescription: description))
                }
                return value
            }
            if let value = `throws`
                ? try decodeIfPresent(type, forKey: codingKey)
                : try? decodeIfPresent(type, forKey: codingKey) {
                return value
            }
        }
        catch { caughtError = error }
        
        if contains(codingKey),
           let value = decodeForTypeConversion(codingKey, as: type, converter: converter) {
            return value
        }
        
        if let caughtError { throw caughtError }
        return nil
    }
    
    func decodeForTypeConversion<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, converter specificConverter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
        
        // `UInt64("1.2")` -> `nil`
        // `Double("1.2")` -> `1.2`
        // `1.2.rounded(.towardZero)` -> `1.0`
        // `UInt64(1.0)` -> `1`
        // !!!: BUT `UInt64(Double(UInt64.max)) != UInt64.max`
        func value<I>(from string: String, _ closure: (Double) -> I?) -> I? {
            return if let double = Double(string) { closure(double.rounded(.towardZero)) } else { nil }
        }
        
        // for nested optionals, e.g. `var int: Int??? = nil`
        let wrappedType = T?.wrappedType
        
        if type is Bool.Type || wrappedType is Bool.Type {
            if let int = try? decodeIfPresent(Int.self, forKey: codingKey) {
                return (int != 0) as? T
            }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
                switch string.lowercased() {
                    case "true", "t", "yes", "y":
                        return true as? T
                    case "false", "f", "no", "n", "":
                        return false as? T
                    default:
                        if let int = Int(string) ?? value(from: string, { Int(exactly: $0) }) { return (int != 0) as? T }
                }
            }
        }
        
        else if type is Int.Type || wrappedType is Int.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = Int(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = Int(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int(string) ?? value(from: string, { Int(exactly: $0) }) { return value as? T }
        }
        else if type is Int8.Type || wrappedType is Int8.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int8(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = Int8(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = Int8(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int8(string) ?? value(from: string, { Int8(exactly: $0) }) { return value as? T }
        }
        else if type is Int16.Type || wrappedType is Int16.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int16(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = Int16(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = Int16(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int16(string) ?? value(from: string, { Int16(exactly: $0) }) { return value as? T }
        }
        else if type is Int32.Type || wrappedType is Int32.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int32(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = Int32(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = Int32(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int32(string) ?? value(from: string, { Int32(exactly: $0) }) { return value as? T }
        }
        else if type is Int64.Type || wrappedType is Int64.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int64(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = Int64(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = Int64(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int64(string) ?? value(from: string, { Int64(exactly: $0) }) { return value as? T }
        }
        
        else if type is UInt.Type || wrappedType is UInt.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = UInt(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = UInt(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt(string) ?? value(from: string, { UInt(exactly: $0) }) { return value as? T }
        }
        else if type is UInt8.Type || wrappedType is UInt8.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt8(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = UInt8(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = UInt8(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt8(string) ?? value(from: string, { UInt8(exactly: $0) }) { return value as? T }
        }
        else if type is UInt16.Type || wrappedType is UInt16.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt16(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = UInt16(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = UInt16(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt16(string) ?? value(from: string, { UInt16(exactly: $0) }) { return value as? T }
        }
        else if type is UInt32.Type || wrappedType is UInt32.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt32(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = UInt32(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = UInt32(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt32(string) ?? value(from: string, { UInt32(exactly: $0) }) { return value as? T }
        }
        else if type is UInt64.Type || wrappedType is UInt64.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt64(bool ? 1 : 0) as? T }
            // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = UInt64(exactly: int64) { return value as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = UInt64(exactly: double.rounded(.towardZero)) { return value as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt64(string) ?? value(from: string, { UInt64(exactly: $0) }) { return value as? T }
        }
        
        else if type is Double.Type || wrappedType is Double.Type {
            // if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return Double(int64) as? T }
            if      let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Double(string) { return value as? T }
        }
        else if type is Float.Type || wrappedType is Float.Type {
            // if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return Float(int64) as? T }
            if      let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Float(string) { return value as? T }
        }
        else if type is Float16.Type || wrappedType is Float16.Type {
            if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return Float16(exactly: int64) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Float16(string) { return value as? T }
        }
        // public typealias Float32 = Float
        // public typealias Float64 = Double
        else if type is CGFloat.Type || wrappedType is CGFloat.Type {
            // if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return CGFloat(int64) as? T }
            if      let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Double(string) { return CGFloat(value) as? T }
        }
        
        else if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
            if type is Int128.Type || wrappedType is Int128.Type {
                if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int128(bool ? 1 : 0) as? T }
                // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = Int128(exactly: int64) { return value as? T }
                else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = Int128(exactly: double.rounded(.towardZero)) { return value as? T }
                else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int128(string) ?? value(from: string, { Int128(exactly: $0) }) { return value as? T }
            }
            else if type is UInt128.Type || wrappedType is UInt128.Type {
                if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt128(bool ? 1 : 0) as? T }
                // else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey), let value = UInt128(exactly: int64) { return value as? T }
                else if let double = try? decodeIfPresent(Double.self, forKey: codingKey), let value = UInt128(exactly: double.rounded(.towardZero)) { return value as? T }
                    else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt128(string) ?? value(from: string, { UInt128(exactly: $0) }) { return value as? T }
            }
        }
        
        if type is String.Type || wrappedType is String.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return String(describing: bool) as? T }
            else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return String(describing: int64) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return String(describing: double) as? T }
            else if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
                if      let  int128 = try? decodeIfPresent(Int128.self,  forKey: codingKey) { return String(describing:  int128) as? T }
                else if let uInt128 = try? decodeIfPresent(UInt128.self, forKey: codingKey) { return String(describing: uInt128) as? T }
            }
        }
        
        // converter for specific type, via `extension T: ExCodableDecodingTypeConverter`
        if let specificConverter,
           let value = specificConverter.decode(self, codingKey: codingKey, as: type) {
            return value
        }
        
        // global converter for all types, via `extension ExCodableGlobalDecodingTypeConverter: ExCodableDecodingTypeConverter`
        if let globalConverter = ExCodableGlobalDecodingTypeConverter.self as? ExCodableDecodingTypeConverter.Type,
           let value = globalConverter.decode(self, codingKey: codingKey, as: type) {
            return value
        }
        
        return nil
    }
}

public protocol ExCodableDecodingTypeConverter {
    static func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T?
}
public struct ExCodableGlobalDecodingTypeConverter {}

// MARK: - Encodable & Decodable - external

// Methods defined in JSON&PList Encoder&Decoder
public protocol DataEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}
public protocol DataDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONEncoder: DataEncoder {}
extension JSONDecoder: DataDecoder {}

extension PropertyListEncoder: DataEncoder {}
extension PropertyListDecoder: DataDecoder {}

// Encodable.encode() -> Data?
public extension Encodable {
    func encoded(using encoder: DataEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }
    func encoded(using encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try encoded(using: encoder) as Data
        return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String: Any]
    }
    func encoded(using encoder: JSONEncoder = JSONEncoder()) throws -> [Any] {
        let data = try encoded(using: encoder) as Data
        return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [Any]
    }
    func encoded(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
        let data = try encoded(using: encoder) as Data
        return String(data: data, encoding: .utf8)!
    }
}

// Decodable.decode(Data) -> Decodable?
public extension Decodable {
    static func decoded(from data: Data, using decoder: DataDecoder = JSONDecoder(), as type: Self.Type = Self.self) throws -> Self {
        return try decoder.decode(type, from: data)
    }
    static func decoded(from json: [String: Any], using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
        return try decoder.decode(type, from: data)
    }
    static func decoded(from jsonArray: [Any], using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: jsonArray, options: .fragmentsAllowed)
        return try decoder.decode(type, from: data)
    }
    static func decoded(from string: String, using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) throws -> Self {
        let data = Data(string.utf8)
        return try decoder.decode(type, from: data)
    }
}

// Data.decode() -> Decodable?
public extension Data {
    func decoded<T: Decodable>(using decoder: DataDecoder = JSONDecoder(), as type: T.Type = T.self) throws -> T {
        return try decoder.decode(type, from: self)
    }
}
public extension Dictionary {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed)
        return try data.decoded(using: decoder, as: type)
    }
}
public extension Array {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed)
        return try data.decoded(using: decoder, as: type)
    }
}
public extension String {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) throws -> T {
        return try Data(self.utf8).decoded(using: decoder, as: type)
    }
}

// MARK: - OptionalProtocol for Nested Optional

// - seealso: https://forums.swift.org/t/challenge-finding-base-type-of-nested-optionals/25096

public protocol OptionalProtocol {
    static var wrappedType: Any.Type { get }
    var wrapped: Any? { get }
}

extension Optional: OptionalProtocol {
    
    public static var wrappedType: Any.Type {
        if let optional = Wrapped.self as? OptionalProtocol.Type {
            return optional.wrappedType
        }
        return Wrapped.self
    }
    
    public var wrapped: Any? {
        return switch self {
            case .some(let optional as OptionalProtocol):
                optional.wrapped
            case .some(let wrapped):
                wrapped
            case .none:
                nil
        }
    }
}
