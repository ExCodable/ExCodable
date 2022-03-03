//
//  ExCodable.swift
//  ExCodable
//
//  Created by Mr. Míng on 2021-02-10.
//  Copyright (c) 2021 Mr. Míng <minglq.9@gmail.com>. Released under the MIT license.
//

import Foundation

/**
 *  # ExCodable
 *  
 *  - `ExCodable`: A property-wrapper for mapping properties to JSON keys.
 *  - `ExAutoEncodable` & `ExAutoDecodable`: Protocols with default implementation for Encodable & Decodable.
 *  - `ExAutoCodable`: A typealias for `ExAutoEncodable & ExAutoDecodable`.
 *  - `Encodable` & `Decodable` extensions for encode/decode-ing from internal/external.
 *  - `Encoder` & `Encoder` extensions for encode/decode-ing properties one by one.
 *  - Supports Alternative-Keys, Nested-Keys, Type-Conversions and Default-Values.
 *  
 *  <#swift#> <#codable#> <#json#> <#model#> <#type-inference#>
 *  <#key-mapping#> <#property-wrapper#> <#coding-key#> <#subscript#>
 *  <#alternative-keys#> <#nested-keys#> <#type-conversions#>
 *  
 *  - seealso: [Usage](https://github.com/iwill/ExCodable#usage) from the `README.md`
 *  - seealso: `ExCodableTests.swift` from the `Tests`
 *  - seealso: [Decoding and overriding](https://www.swiftbysundell.com/articles/property-wrappers-in-swift/#decoding-and-overriding) and [Useful Codable extensions](https://www.swiftbysundell.com/tips/useful-codable-extensions/), by John Sundell.
 */

@propertyWrapper
public final class ExCodable<Value> {
    fileprivate let stringKeys: [String]?
    fileprivate let nonnull, `throws`: Bool?
    fileprivate let encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?, decode: ((_ decoder: Decoder) throws -> Value?)?
    public var wrappedValue: Value
    private init(wrappedValue: Value, stringKeys: [String]? = nil, nonnull: Bool? = nil, throws: Bool? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?, decode: ((_ decoder: Decoder) throws -> Value?)?) {
        (self.wrappedValue, self.stringKeys, self.nonnull, self.throws, self.encode, self.decode) = (wrappedValue, stringKeys, nonnull, `throws`, encode, decode)
    }
    public convenience init(wrappedValue: Value, _ stringKey: String? = nil, nonnull: Bool? = nil, throws: Bool? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKey.map { [$0] }, nonnull: nonnull, throws: `throws`, encode: encode, decode: decode)
    }
    public convenience init(wrappedValue: Value, _ stringKeys: String..., nonnull: Bool? = nil, throws: Bool? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKeys, nonnull: nonnull, throws: `throws`, encode: encode, decode: decode)
    }
    public convenience init(wrappedValue: Value, _ codingKeys: CodingKey..., nonnull: Bool? = nil, throws: Bool? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: codingKeys.map { $0.stringValue }, nonnull: nonnull, throws: `throws`, encode: encode, decode: decode)
    }
}
extension ExCodable: Equatable where Value: Equatable {
    public static func == (lhs: ExCodable<Value>, rhs: ExCodable<Value>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

fileprivate protocol EncodablePropertyWrapper {
    func encode<Label: StringProtocol>(to encoder: Encoder, label: Label, nonnull: Bool, throws: Bool) throws
}
extension ExCodable: EncodablePropertyWrapper where Value: Encodable {
    fileprivate func encode<Label: StringProtocol>(to encoder: Encoder, label: Label, nonnull: Bool, throws: Bool) throws {
        if encode != nil { try encode!(encoder, wrappedValue) }
        else { try encoder.encode(wrappedValue, for: stringKeys?.first ?? String(label), nonnull: self.nonnull ?? nonnull, throws: self.throws ?? `throws`) }
    }
}

fileprivate protocol DecodablePropertyWrapper {
    func decode<Label: StringProtocol>(from decoder: Decoder, label: Label, nonnull: Bool, throws: Bool) throws
}
extension ExCodable: DecodablePropertyWrapper where Value: Decodable {
    fileprivate func decode<Label: StringProtocol>(from decoder: Decoder, label: Label, nonnull: Bool, throws: Bool) throws {
        if let value = decode != nil
            ? try decode!(decoder)
            : try decoder.decode(stringKeys ?? [String(label)], nonnull: self.nonnull ?? nonnull, throws: self.throws ?? `throws`) {
            wrappedValue = value
        }
    }
}

// MARK: - Auto implementation for Encodable & Decodable

public protocol ExAutoEncodable: Encodable {}
public extension ExAutoEncodable {
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, nonnull: false, throws: false)
    }
}

public protocol ExAutoDecodable: Decodable { init() }
public extension ExAutoDecodable {
    init(from decoder: Decoder) throws {
        self.init()
        try decode(from: decoder, nonnull: false, throws: false)
    }
}

public typealias ExAutoCodable = ExAutoEncodable & ExAutoDecodable

// MARK: - Encodable & Decodable - internal

public extension Encodable {
    func encode(to encoder: Encoder, nonnull: Bool, throws: Bool) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                try (child.value as? EncodablePropertyWrapper)?.encode(to: encoder, label: child.label!.dropFirst(), nonnull: false, throws: false)
            }
            mirror = mirror.superclassMirror
        }
    }
}

public extension Decodable {
    func decode(from decoder: Decoder, nonnull: Bool, throws: Bool) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                try (child.value as? DecodablePropertyWrapper)?.decode(from: decoder, label: child.label!.dropFirst(), nonnull: false, throws: false)
            }
            mirror = mirror.superclassMirror
        }
    }
}

// MARK: - Encoder & Decoder

public extension Encoder { // , abortIfNull nonnull: Bool = false, abortOnError throws: Bool = false
    subscript<T: Encodable>(stringKey: String) -> T? { get { return nil }
        nonmutating set { encode(newValue, for: stringKey) }
    }
    subscript<T: Encodable, K: CodingKey>(codingKey: K) -> T? { get { return nil }
        nonmutating set { encode(newValue, for: codingKey) }
    }
}

public extension Decoder { // , abortIfNull nonnull: Bool = false, abortOnError throws: Bool = false
    subscript<T: Decodable>(stringKeys: [String]) -> T? {
        return decode(stringKeys, as: T.self)
    }
    subscript<T: Decodable>(stringKeys: String ...) -> T? {
        return decode(stringKeys, as: T.self)
    }
    subscript<T: Decodable, K: CodingKey>(codingKeys: [K]) -> T? {
        return decode(codingKeys, as: T.self)
    }
    subscript<T: Decodable, K: CodingKey>(codingKeys: K ...) -> T? {
        return decode(codingKeys, as: T.self)
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
    internal/* fileprivate */ func encode<T: Encodable>(_ value: T?, for stringKey: String, nonnull: Bool = false, throws: Bool = false) throws {
        
        let dot: Character = "."
        guard stringKey.contains(dot), stringKey.count > 1 else {
            try encode(value, for: ExCodingKey(stringKey), nonnull: nonnull, throws: `throws`)
            return
        }
        
        let keys = stringKey.split(separator: dot).map { ExCodingKey($0) }
        var container = self.container(keyedBy: ExCodingKey.self)
        for key in keys.dropLast() {
            container = container.nestedContainer(keyedBy: ExCodingKey.self, forKey: key)
        }
        
        let codingKey = keys.last!
        do {
            if nonnull { try container.encode(value, forKey: codingKey) }
            else { try container.encodeIfPresent(value, forKey: codingKey) }
        }
        catch { if `throws` || nonnull { throw error } }
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
    internal/* fileprivate */ func encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K, nonnull: Bool = false, throws: Bool = false) throws {
        var container = self.container(keyedBy: K.self)
        do {
            if nonnull { try container.encode(value, forKey: codingKey) }
            else { try container.encodeIfPresent(value, forKey: codingKey) }
        }
        catch { if `throws` || nonnull { throw error } }
    }
}

public extension Decoder {
    
    func decodeNonnullThrows<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self) throws -> T {
        return try decodeNonnullThrows(stringKeys, as: type)
    }
    func decodeNonnullThrows<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self) throws -> T {
        return try decode(stringKeys, as: type, nonnull: true, throws: true)!
    }
    func decodeThrows<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self) throws -> T? {
        return try decodeThrows(stringKeys, as: type)
    }
    func decodeThrows<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self) throws -> T? {
        return try decode(stringKeys, as: type, nonnull: false, throws: true)
    }
    func decode<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self) -> T? {
        return decode(stringKeys, as: type)
    }
    func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self) -> T? {
        return try? decode(stringKeys, as: type, nonnull: false, throws: false)
    }
    internal/* fileprivate */ func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false) throws -> T? {
        return try decode(stringKeys.map { ExCodingKey($0) }, as: type, nonnull: nonnull, throws: `throws`)
    }
    
    func decodeNonnullThrows<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self) throws -> T {
        return try decodeNonnullThrows(codingKeys, as: type)
    }
    func decodeNonnullThrows<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self) throws -> T {
        return try decode(codingKeys, as: type, nonnull: true, throws: true)!
    }
    func decodeThrows<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self) throws -> T? {
        return try decodeThrows(codingKeys, as: type)
    }
    func decodeThrows<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self) throws -> T? {
        return try decode(codingKeys, as: type, nonnull: false, throws: true)
    }
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self) -> T? {
        return decode(codingKeys, as: type)
    }
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self) -> T? {
        return try? decode(codingKeys, as: type, nonnull: false, throws: false)
    }
    internal/* fileprivate */ func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false) throws -> T? {
        do {
            let container = try self.container(keyedBy: K.self)
            return try container.decodeForAlternativeKeys(codingKeys, as: type, nonnull: nonnull, throws: `throws`)
        }
        catch { if `throws` || nonnull { throw error } }
        return nil
    }
}

// MARK: - ExCodingKey

private struct ExCodingKey {
    public let stringValue: String, intValue: Int?
    init<S: LosslessStringConvertible>(_ stringValue: S) { (self.stringValue, self.intValue) = (stringValue as? String ?? String(stringValue), nil) }
}

extension ExCodingKey: CodingKey {
    public init?(stringValue: String) { self.init(stringValue) }
    public init?(intValue: Int) { self.init(intValue) }
}

// MARK: - KeyedDecodingContainer - alternative-keys + nested-keys + type-conversions

fileprivate extension KeyedDecodingContainer {
    
    func decodeForAlternativeKeys<T: Decodable>(_ codingKeys: [Self.Key], as type: T.Type = T.self, nonnull: Bool, throws: Bool) throws -> T? {
        
        var firstError: Error?
        do {
            let codingKey = codingKeys.first!
            if let value = try decodeForNestedKeys(codingKey, as: type, nonnull: nonnull, throws: `throws`) {
                return value
            }
        }
        catch { firstError = error }
        
        let codingKeys = Array(codingKeys.dropFirst())
        if !codingKeys.isEmpty,
           let value = try? decodeForAlternativeKeys(codingKeys, as: type, nonnull: nonnull, throws: `throws`) {
            return value
        }
        
        if (`throws` || nonnull) && firstError != nil { throw firstError! }
        return nil
    }
    
    func decodeForNestedKeys<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, nonnull: Bool, throws: Bool) throws -> T? {
        
        var firstError: Error?
        do {
            if let value = try decodeForValue(codingKey, as: type, nonnull: nonnull, throws: `throws`) {
                return value
            }
        }
        catch { firstError = error }
        
        let dot: Character = "."
        if let exCodingKey = codingKey as? ExCodingKey, // Self.Key is ExCodingKey.Type
           exCodingKey.intValue == nil && exCodingKey.stringValue.contains(dot) {
            let keys = exCodingKey.stringValue.split(separator: dot).map { ExCodingKey($0) }
            if !keys.isEmpty,
               let container = nestedContainer(with: keys.dropLast()),
               let codingKey = keys.last,
               let value = try? container.decodeForNestedKeys(codingKey as! Self.Key, as: type, nonnull: nonnull, throws: `throws`) {
                return value
            }
        }
        
        if firstError != nil && (`throws` || nonnull) { throw firstError! }
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
    
    func decodeForValue<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, nonnull: Bool, throws: Bool) throws -> T? {
        
        var firstError: Error?
        do {
            if let value = nonnull
                ? (`throws` ? try decode(type, forKey: codingKey) : try? decode(type, forKey: codingKey))
                : (`throws` ? try decodeIfPresent(type, forKey: codingKey) : try? decodeIfPresent(type, forKey: codingKey)) {
                return value
            }
        }
        catch { firstError = error }
        
        if contains(codingKey),
           let value = decodeForTypeConversion(codingKey, as: type) {
            return value
        }
        
        if firstError != nil && (`throws` || nonnull) { throw firstError! }
        return nil
    }
    
    func decodeForTypeConversion<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self) -> T? {
        
        if type is Bool.Type {
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
                        if let int = Int(string) { return (int != 0) as? T }
                        else if let double = Double(string) { return (Int(double) != 0) as? T }
                }
            }
        }
        
        else if type is Int.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int(string) { return value as? T }
        }
        else if type is Int8.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int8(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int8(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int8(string) { return value as? T }
        }
        else if type is Int16.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int16(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int16(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int16(string) { return value as? T }
        }
        else if type is Int32.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int32(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int32(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int32(string) { return value as? T }
        }
        else if type is Int64.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int64(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int64(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int64(string) { return value as? T }
        }
        else if type is UInt.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt(string) { return value as? T }
        }
        else if type is UInt8.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt8(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt8(string) { return value as? T }
        }
        else if type is UInt16.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt16(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt16(string) { return value as? T }
        }
        else if type is UInt32.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt32(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt32(string) { return value as? T }
        }
        else if type is UInt64.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt64(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt64(string) { return value as? T }
        }
        
        else if type is Double.Type {
            if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return Double(int64) as? T } // include all Int types
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Double(string) { return value as? T }
        }
        else if type is Float.Type {
            if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return Float(int64) as? T } // include all Int types
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Float(string) { return value as? T }
        }
        
        else if type is String.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return String(describing: bool) as? T }
            else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return String(describing: int64) as? T } // include all Int types
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return String(describing: double) as? T } // include Float
        }
        
        for converter in _decodingTypeConverters {
            if let value = try? converter.decode(self, codingKey: codingKey, as: type) {
                return value
            }
        }
        if let customConverter = self as? ExCodableDecodingTypeConverter,
           let value = try? customConverter.decode(self, codingKey: codingKey, as: type) {
            return value
        }
        
        return nil
    }
}

public protocol ExCodableDecodingTypeConverter {
    func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) throws -> T?
}

fileprivate var _decodingTypeConverters: [ExCodableDecodingTypeConverter] = []
public func register(_ decodingTypeConverter: ExCodableDecodingTypeConverter) {
    _decodingTypeConverters.append(decodingTypeConverter)
}

// MARK: - Encodable & Decodable - external

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

// Methods from JSON&PList Encoder&Decoder
public protocol DataEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}
public protocol DataDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONEncoder: DataEncoder {}
extension JSONDecoder: DataDecoder {}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension PropertyListEncoder: DataEncoder {}
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension PropertyListDecoder: DataDecoder {}
