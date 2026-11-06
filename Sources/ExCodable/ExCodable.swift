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
/// <#macro#> <#key-mapping#> <#coding-key#> <#subscript#>
/// <#alternative-keys#> <#nested-keys#> <#type-conversions#>
/// <#default-value#> <#custom-encoding#> <#custom-decoding#>
/// 
/// - `ExCodable`: A macro generates `init(from:)` and `encode(to:)`.
/// - `ExCodableKey`: A macro associates JSON keys to properties.
/// - `Encodable` & `Decodable` extensions for encoding/decoding from internal/external.
/// - `Encoder` & `Encoder` extensions for encoding/decoding properties one by one.
/// - Supports alternative keys, nested keys, type conversions, nested optionals, default values, custom encoding, custom decoding, etc.
/// 
/// - seealso: [Usage](https://github.com/ExCodable/ExCodable#usage) from the `README.md`
/// - seealso: `ExCodableTests.swift` from the `Tests`
/// - seealso: [Decoding and overriding](https://www.swiftbysundell.com/articles/property-wrappers-in-swift/#decoding-and-overriding)
/// and [Useful Codable extensions](https://www.swiftbysundell.com/tips/useful-codable-extensions/), by John Sundell.

// MARK: - Encoder & Decoder

public extension Encoder {
    subscript<T: Encodable>(stringKey: String) -> T? { get { return nil }
        nonmutating set { encode(newValue, for: stringKey) }
    }
    subscript<T: Encodable, K: CodingKey>(codingKey: K) -> T? { get { return nil }
        nonmutating set { encode(newValue, for: codingKey) }
    }
}

public extension Decoder {
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
    
    func encode<T: Encodable>(_ value: T?, for stringKey: String) {
        try? encode(value, for: stringKey, optional: true, strictType: false)
    }
    
    internal func encode<T: Encodable>(_ value: T?, for stringKey: String, optional: Bool = true, strictType: Bool = false) throws {
        
        let keys = stringKey.split(separator: ".").map { ExCodingKey($0) }
        guard keys.count > 1 else {
            try encode(value, for: keys.first ?? ExCodingKey(stringKey), optional: optional, strictType: strictType)
            return
        }
        
        let codingKey = keys.last!
        var container = container(keyedBy: ExCodingKey.self)
        for key in keys.dropLast() {
            container = container.nestedContainer(keyedBy: ExCodingKey.self, forKey: key)
        }
        
        // throws `EncodingError.invalidValue`
        if !optional {
            if value.wrapped == nil {
                let desc = "Expected to encode a required \(T?.wrappedType) but found null value instead."
                throw EncodingError.invalidValue(value as Any, .init(codingPath: [ExCodingKey(stringKey)], debugDescription: desc))
            }
            try container.encode(value, forKey: codingKey)
        }
        // throws `EncodingError.invalidValue`
        else if strictType {
            try container.encodeIfPresent(value, forKey: codingKey)
        }
        // NO throws
        else {
            try? container.encodeIfPresent(value, forKey: codingKey)
        }
    }
    
    func encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K) {
        try? encode(value, for: codingKey, optional: true, strictType: false)
    }
    
    internal func encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K, optional: Bool = true, strictType: Bool = false) throws {
        var container = container(keyedBy: K.self)
        // throws `EncodingError.invalidValue`
        if !optional {
            if value.wrapped == nil {
                let desc = "Expected to encode a required \(T?.wrappedType) but found null value instead."
                throw EncodingError.invalidValue(value as Any, .init(codingPath: [codingKey], debugDescription: desc))
            }
            try container.encode(value, forKey: codingKey)
        }
        // throws `EncodingError.invalidValue`
        else if strictType {
            try container.encodeIfPresent(value, forKey: codingKey)
        }
        // NO throws
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
    
    func decode<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
        return decode(stringKeys, as: type, converter: converter)
    }
    func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
        return try? decode(stringKeys, as: type, optional: true, strictType: false, converter: converter)
    }
    
    internal func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, optional: Bool = true, strictType: Bool = false, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        return try decode(stringKeys.map { ExCodingKey($0) }, as: type, optional: optional, strictType: strictType, converter: converter)
    }
    
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
        return decode(codingKeys, as: type, converter: converter)
    }
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, converter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
        return try? decode(codingKeys, as: type, optional: true, strictType: false, converter: converter)
    }
    
    internal func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, optional: Bool = true, strictType: Bool = false, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        let `throws` = !optional || strictType
        if let container = (`throws`
                            ? try  container(keyedBy: K.self)
                            : try? container(keyedBy: K.self)) {
            return (`throws`
                    ? try  container.decodeForKeys(codingKeys, as: type, optional: optional, strictType: strictType, converter: converter)
                    : try? container.decodeForKeys(codingKeys, as: type, optional: optional, strictType: strictType, converter: converter))
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
    
    // call decodeForKey: `try` only and `throws` - NEVER swallow errors
    func decodeForKeys<T: Decodable>(_ codingKeys: [Self.Key], as type: T.Type = T.self, optional: Bool, strictType: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        
        // `keyNotFound` only says that an attempt found nothing, while any other error says that no value was found or a value was wrong.
        // So an earlier `keyNotFound` gives way to a new error, and otherwise the first error stays.
        func which(_ lastError: Error?, _ error: Error) -> Error {
            guard let lastError else { return error }
            guard case DecodingError.keyNotFound = lastError else { return lastError }
            guard case DecodingError.keyNotFound = error else { return error }
            return lastError // both keyNotFound
        }
        
        let codingKey = codingKeys.first!
        var prevError: Error?
        
        do { if let value = try decodeForKey(codingKey, as: type, optional: optional, strictType: strictType, converter: converter) {
            return value
        }}
        catch { prevError = which(prevError, error) }
        
        do { if let value = try decodeForNestedKey(codingKey, as: type, optional: optional, strictType: strictType, converter: converter) {
            return value
        }}
        catch { prevError = which(prevError, error) }
        
        do {
            let alternativeKeys = Array(codingKeys.dropFirst())
            if !alternativeKeys.isEmpty,
               let value = try decodeForKeys(alternativeKeys, as: type, optional: optional, strictType: strictType, converter: converter) {
                return value
            }
        }
        catch { prevError = which(prevError, error) }
        
        if let prevError { throw prevError }
        return nil
    }
    
    // call decodeForKey: `try` only and `throws` - NEVER swallow errors
    func decodeForNestedKey<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, optional: Bool, strictType: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        // Self.Key is ExCodingKey.Type
        guard let exCodingKey = codingKey as? ExCodingKey, exCodingKey.intValue == nil else { return nil }
        let keys = exCodingKey.stringValue.split(separator: ".").map { ExCodingKey($0) }
        guard keys.count > 1, let codingKey = keys.last, let container = nestedContainer(with: keys.dropLast()) else {
            return nil
        }
        return try container.decodeForKey(codingKey as! Self.Key, as: type, optional: optional, strictType: strictType, converter: converter)
    }
    
    // do decode: use `try` only if `!optional` || `strictType`, else use `try?`
    func decodeForKey<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, optional: Bool, strictType: Bool, converter: (any ExCodableDecodingTypeConverter.Type)?) throws -> T? {
        var prevError: Error?
        do {
            
            if !optional {
                // throws `DecodingError.keyNotFound`, `DecodingError.valueNotFound`, `DecodingError.typeMismatch`, `DecodingError.dataCorrupted` and numberIsNotRepresentableInSwift(parsed: ...), etc.
                let value = try decode(type, forKey: codingKey)
                // throws `DecodingError.valueNotFound` for `Optional.none`
                if let optional = value as? OptionalProtocol, optional.wrapped == nil {
                    let description = "Value not found with key \(codingKey) (\"\(codingKey.stringValue)\")."
                    throw DecodingError.valueNotFound(T.self, .init(codingPath: codingPath, debugDescription: description))
                }
                return value
            }
            
            if let value = (strictType
                            // throws `DecodingError.typeMismatch`
                            ? try decodeIfPresent(type, forKey: codingKey)
                            // NO throws
                            : try? decodeIfPresent(type, forKey: codingKey)) {
                return value
            }
        }
        catch { prevError = prevError ?? error }
        
        if contains(codingKey) {
            if let value = decodeForTypeConversion(codingKey, as: type, converter: converter) {
                return value
            }
        }
        
        if let prevError { throw prevError }
        return nil
    }
    
    // type conversions: just `try?` and NO `throws` - value is optional
    func decodeForTypeConversion<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, converter specificConverter: (any ExCodableDecodingTypeConverter.Type)?) -> T? {
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
                        if let int = Int(string) ?? parseDecimal(from: string, toInt64: { Int(exactly: $0) }) { return (int != 0) as? T }
                }
            }
        }
        
        else if type is Int.Type || wrappedType is Int.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return Int(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let int64 = roundToInt64(decimal), let value = Int(exactly: int64) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = Int(string) ?? parseDecimal(from: string, toInt64: { Int(exactly: $0) }) { return value as? T }
        }
        else if type is Int8.Type || wrappedType is Int8.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return Int8(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let int64 = roundToInt64(decimal), let value = Int8(exactly: int64) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = Int8(string) ?? parseDecimal(from: string, toInt64: { Int8(exactly: $0) }) { return value as? T }
        }
        else if type is Int16.Type || wrappedType is Int16.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return Int16(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let int64 = roundToInt64(decimal), let value = Int16(exactly: int64) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = Int16(string) ?? parseDecimal(from: string, toInt64: { Int16(exactly: $0) }) { return value as? T }
        }
        else if type is Int32.Type || wrappedType is Int32.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return Int32(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let int64 = roundToInt64(decimal), let value = Int32(exactly: int64) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = Int32(string) ?? parseDecimal(from: string, toInt64: { Int32(exactly: $0) }) { return value as? T }
        }
        else if type is Int64.Type || wrappedType is Int64.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return Int64(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let value = roundToInt64(decimal) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = Int64(string) ?? parseDecimal(from: string, toInt64: { Int64(exactly: $0) }) { return value as? T }
        }
        
        else if type is UInt.Type || wrappedType is UInt.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return UInt(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let uInt64 = roundToUInt64(decimal), let value = UInt(exactly: uInt64) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = UInt(string) ?? parseDecimal(from: string, toUInt64: { UInt(exactly: $0) }) { return value as? T }
        }
        else if type is UInt8.Type || wrappedType is UInt8.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return UInt8(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let uInt64 = roundToUInt64(decimal), let value = UInt8(exactly: uInt64) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = UInt8(string) ?? parseDecimal(from: string, toUInt64: { UInt8(exactly: $0) }) { return value as? T }
        }
        else if type is UInt16.Type || wrappedType is UInt16.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return UInt16(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let uInt64 = roundToUInt64(decimal), let value = UInt16(exactly: uInt64) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = UInt16(string) ?? parseDecimal(from: string, toUInt64: { UInt16(exactly: $0) }) { return value as? T }
        }
        else if type is UInt32.Type || wrappedType is UInt32.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return UInt32(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let uInt64 = roundToUInt64(decimal), let value = UInt32(exactly: uInt64) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = UInt32(string) ?? parseDecimal(from: string, toUInt64: { UInt32(exactly: $0) }) { return value as? T }
        }
        else if type is UInt64.Type || wrappedType is UInt64.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return UInt64(bool ? 1 : 0) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let value = roundToUInt64(decimal) { return value as? T }
            else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = UInt64(string) ?? parseDecimal(from: string, toUInt64: { UInt64(exactly: $0) }) { return value as? T }
        }
        
        else if type is Double.Type || wrappedType is Double.Type {
            if      let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = Double(string), value.isFinite { return value as? T }
        }
        else if type is Float.Type || wrappedType is Float.Type {
            if      let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = Float(string), value.isFinite { return value as? T }
        }
        else if type is Float16.Type || wrappedType is Float16.Type {
            if      let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = Float16(string), value.isFinite { return value as? T }
        }
        // public typealias Float32 = Float
        // public typealias Float64 = Double
        else if type is CGFloat.Type || wrappedType is CGFloat.Type {
            if      let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let value = Double(string), value.isFinite { return CGFloat(value) as? T }
        }
        
        else if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
            if type is Int128.Type || wrappedType is Int128.Type {
                if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return Int128(bool ? 1 : 0) as? T }
                else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let value = Int128((round(decimal) as NSDecimalNumber).stringValue) { return value as? T }
                else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let prefix = integerPrefix(string), let value = Int128(prefix) { return value as? T }
            }
            else if type is UInt128.Type || wrappedType is UInt128.Type {
                if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return UInt128(bool ? 1 : 0) as? T }
                else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey), let value = UInt128((round(decimal) as NSDecimalNumber).stringValue) { return value as? T }
                else if let string  = try? decodeIfPresent(String.self,  forKey: codingKey), let prefix = integerPrefix(string), let value = UInt128(prefix) { return value as? T }
            }
        }
        
        if type is String.Type || wrappedType is String.Type {
            if      let bool    = try? decodeIfPresent(Bool.self,    forKey: codingKey) { return String(describing: bool) as? T }
            else if let int64   = try? decodeIfPresent(Int64.self,   forKey: codingKey) { return String(describing: int64) as? T }
            else if let decimal = try? decodeIfPresent(Decimal.self, forKey: codingKey) { return String(describing: decimal) as? T }
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
        
        return nil
    }
    
    // nested container: just `try?` and NO `throws` - key is optional
    private func nestedContainer(with keys: [ExCodingKey]) -> Self? {
        var container: Self? = self
        for key in keys {
            container = try? container?.nestedContainer(keyedBy: Self.Key.self, forKey: key as! Self.Key)
            if container == nil { return nil }
        }
        return container
    }
}

// MARK: - private funcs

fileprivate func round(_ decimal: Decimal) -> Decimal {
    var decimal = decimal, rounded: Decimal = 0
    NSDecimalRound(&rounded, &decimal, 0, decimal < 0 ? .up : .down)
    return rounded
}
fileprivate func roundToInt64(_ decimal: Decimal) -> Int64? {
    let rounded = round(decimal)
    let int64 = (rounded as NSDecimalNumber).int64Value
    guard Decimal(int64) == rounded else { return nil }
    return int64
}
fileprivate func roundToUInt64(_ decimal: Decimal) -> UInt64? {
    let rounded = round(decimal)
    let uInt64 = (rounded as NSDecimalNumber).uint64Value
    guard Decimal(uInt64) == rounded else { return nil }
    return uInt64
}

// `String: "1.2"` -> `UInt64: nil`
// `String: "1.2"` -> `Decimal: 1.2` -> `Decimal: 1` -> `UInt64: 1`
// !!!: USE Decimal, because Double does NOT include Int64 or UInt64
fileprivate func parseDecimal<I>(from string: String, toInt64 make: (_ int64: Int64) -> I?) -> I? {
    guard let string = integerPrefix(string), let decimal = Decimal(string: String(string)), let int64: Int64 = roundToInt64(decimal) else { return nil }
    return make(int64)
}
fileprivate func parseDecimal<I>(from string: String, toUInt64 make: (_ uInt64: UInt64) -> I?) -> I? {
    guard let string = integerPrefix(string), let decimal = Decimal(string: String(string)), let uInt64: UInt64 = roundToUInt64(decimal) else { return nil }
    return make(uInt64)
}

// !!!: BUT Decimal does NOT include Int128 or UInt128
fileprivate func integerPrefix(_ string: String) -> any StringProtocol? {
    return string.wholeMatch(of: /([+-]?[0-9]+)\.?[0-9]*/)?.1
}

/// Converts a decoded value of a different JSON type into `T`.
///
/// `SendableMetatype` lets a converter be kept in a global or passed across tasks without a Swift 6
/// concurrency diagnostic. Unlike `Sendable`, it does not require the conforming type's instances to be `Sendable`.
public protocol ExCodableDecodingTypeConverter: SendableMetatype {
    static func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T?
}

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
