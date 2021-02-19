//
//  ExCodable.swift
//  ExCodable
//
//  Created by Mr. Ming on 2021-02-10.
//  Copyright (c) 2021 Mr. Ming <minglq.9@gmail.com>. Released under the MIT license.
//

import Foundation

/**
 *  # ExCodable
 *  
 *  <#swift#> <#codable#> <#json#> <#model#> <#type-inference#>
 *  <#key-mapping#> <#keypath#> <#codingkey#> <#subscript#>
 *  <#alternative-keys#> <#nested-keys#> <#type-conversion#>
 */

// MARK: - ExCodable

/// A protocol extends `Encodable` & `Decodable` with `keyMapping`
/// - seealso: [Usage](https://github.com/iwill/ExCodable#usage) from GitGub
/// - seealso: `ExCodableTests.swift` form the source code
public protocol ExCodable: Encodable, Decodable {
    associatedtype Root: Encodable, Decodable // Root should be Self, or the Type of Self
    static var keyMapping: [KeyMap<Root>] { get }
}

public extension ExCodable where Root == Self {
    /// Encode both value-type and ref-type
    func encode(with keyMapping: [KeyMap<Root>], using encoder: Encoder) {
        keyMapping.forEach { $0.encode(self, encoder) }
    }
    /// Decode value-type
    mutating func decode(with keyMapping: [KeyMap<Root>], using decoder: Decoder) {
        keyMapping.forEach { $0.decode?(&self, decoder) }
    }
    /// Decode ref-type
    func decodeReference(with keyMapping: [KeyMap<Root>], using decoder: Decoder) {
        keyMapping.forEach { $0.decodeReference?(self, decoder) }
    }
}

// MARK: - key-mapping

public struct KeyMap<Root: Encodable & Decodable> {
    fileprivate let encode: (_ root: Root, _ encoder: Encoder) -> Void
    fileprivate let decode: ((_ root: inout Root, _ decoder: Decoder) -> Void)?
    fileprivate let decodeReference: ((_ root: Root, _ decoder: Decoder) -> Void)?
}

public extension KeyMap {
    
    /// Constructor for value-type with `String` type codingKeys
    init<Value: Encodable & Decodable>(_ keyPath: WritableKeyPath<Root, Value>,
                                       to codingKeys: String ...,
                                       encode: ((Encoder, [String], Root, WritableKeyPath<Root, Value>) -> Void)? = nil,
                                       decode: ((inout Root, WritableKeyPath<Root, Value>, Decoder, [String]) -> Void)? = nil) {
        self.init(encode: { (root, encoder) in
            if encode != nil { encode!(encoder, codingKeys, root, keyPath) }
            else { encoder[codingKeys.first!] = root[keyPath: keyPath] }
        }, decode: { (root, decoder) in
            if decode != nil { decode!(&root, keyPath, decoder, codingKeys)  }
            else if let value: Value = decoder[codingKeys] { root[keyPath: keyPath] = value }
        }, decodeReference: nil)
    }
    
    /// Constructor for value-type with `CodingKey` type codingKeys
    init<Value: Encodable & Decodable, Key: CodingKey>(_ keyPath: WritableKeyPath<Root, Value>,
                                                       to codingKeys: Key ...,
                                                       encode: ((Encoder, [Key], Root, WritableKeyPath<Root, Value>) -> Void)? = nil,
                                                       decode: ((inout Root, WritableKeyPath<Root, Value>, Decoder, [Key]) -> Void)? = nil) {
        self.init(encode: { (root, encoder) in
            if encode != nil { encode!(encoder, codingKeys, root, keyPath) }
            else { encoder[codingKeys.first!] = root[keyPath: keyPath] }
        }, decode: { (root, decoder) in
            if decode != nil { decode!(&root, keyPath, decoder, codingKeys)  }
            else if let value: Value = decoder[codingKeys] { root[keyPath: keyPath] = value }
        }, decodeReference: nil)
    }
    
    /// Constructor for ref-type with `String` type codingKeys
    init<Value: Encodable & Decodable>(ref keyPath: ReferenceWritableKeyPath<Root, Value>,
                                       to codingKeys: String ...,
                                       encode: ((Encoder, [String], Root, ReferenceWritableKeyPath<Root, Value>) -> Void)? = nil,
                                       decode: ((Root, ReferenceWritableKeyPath<Root, Value>, Decoder, [String]) -> Void)? = nil) {
        self.init(encode: { (root, encoder) in
            if encode != nil { encode!(encoder, codingKeys, root, keyPath) }
            else { encoder[codingKeys.first!] = root[keyPath: keyPath] }
        }, decode: nil, decodeReference: { (root, decoder) in
            if decode != nil { decode!(root, keyPath, decoder, codingKeys)  }
            else if let value: Value = decoder[codingKeys] { root[keyPath: keyPath] = value }
        })
    }
    
    /// Constructor for ref-type with `CodingKey` type codingKeys
    init<Value: Encodable & Decodable, Key: CodingKey>(ref keyPath: ReferenceWritableKeyPath<Root, Value>,
                                                       to codingKeys: Key ...,
                                                       encode: ((Encoder, [Key], Root, ReferenceWritableKeyPath<Root, Value>) -> Void)? = nil,
                                                       decode: ((Root, ReferenceWritableKeyPath<Root, Value>, Decoder, [Key]) -> Void)? = nil) {
        self.init(encode: { (root, encoder) in
            if encode != nil { encode!(encoder, codingKeys, root, keyPath) }
            else { encoder[codingKeys.first!] = root[keyPath: keyPath] }
        }, decode: nil, decodeReference: { (root, decoder) in
            if decode != nil { decode!(root, keyPath, decoder, codingKeys)  }
            else if let value: Value = decoder[codingKeys] { root[keyPath: keyPath] = value }
        })
    }
}

// MARK: - subscript

public extension Encoder {
    
    subscript<T>(_ stringKey: String) -> T? where T : Encodable {
        get { return nil }
        nonmutating set { encode(newValue, for: stringKey) }
    }
    
    subscript<T, K>(_ codingKey: K) -> T? where T : Encodable, K : CodingKey {
        get { return nil }
        nonmutating set { encode(newValue, for: codingKey) }
    }
    
}

public extension Decoder {
    
    subscript<T>(_ stringKeys: [String]) -> T? where T : Decodable {
        return decode(stringKeys, as: T.self)
    }
    subscript<T>(_ stringKeys: String ...) -> T? where T : Decodable {
        return decode(stringKeys, as: T.self)
    }
    
    subscript<T, K>(_ codingKeys: [K]) -> T? where T : Decodable, K : CodingKey {
        return decode(codingKeys, as: T.self)
    }
    subscript<T, K>(_ codingKeys: K ...) -> T? where T : Decodable, K : CodingKey {
        return decode(codingKeys, as: T.self)
    }
    
}

// MARK: - Encoder/Decoder

private extension Encoder {
    
    @discardableResult
    func encode<T: Encodable>(_ value: T?, for stringKey: String) -> Bool {
        guard stringKey.contains(".") else {
            return encode(value, for: ExCodingKey(stringKey))
        }
        var container = self.container(keyedBy: ExCodingKey.self)
        let keys = stringKey.split(separator: ".").map { ExCodingKey($0) }
        for key in keys.dropLast() {
            container = container.nestedContainer(keyedBy: ExCodingKey.self, forKey: key)
        }
        if let codingKey = keys.last {
            do {
                try container.encodeIfPresent(value, forKey: codingKey)
                return true
            }
            catch {}
        }
        return false
    }
    
    @discardableResult
    func encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K) -> Bool {
        var container = self.container(keyedBy: K.self)
        do {
            try container.encodeIfPresent(value, forKey: codingKey)
            return true
        }
        catch {}
        return false
    }
    
}

private extension Decoder {
    
    func decode<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self) -> T? {
        return decode(stringKeys, as: type)
    }
    func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self) -> T? {
        return decode(stringKeys.map { ExCodingKey($0) }, as: type)
    }
    
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self) -> T? {
        return decode(codingKeys, as: type)
    }
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self) -> T? {
        let container = try? self.container(keyedBy: K.self)
        return container?.decodeIfPresent(codingKeys, as: type)
    }
    
}

// MARK: alternative-keys

private extension KeyedDecodingContainer {
    func decodeIfPresent<T: Decodable>(_ codingKeys: [Self.Key], as type: T.Type = T.self) -> T? {
        guard let codingKey = codingKeys.first else {
            return nil
        }
        if let value = decodeIfPresent(codingKey, as: type) {
            return value
        }
        return decodeIfPresent(Array(codingKeys.dropFirst()), as: type)
    }
}

// MARK: nested-keys

private extension KeyedDecodingContainer {
    func decodeIfPresent<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self) -> T? {
        if let value = decodeIfTypeConvertible(codingKey, as: type) {
            return value
        }
        if let exCodingKey = codingKey as? ExCodingKey, // Self.Key is ExCodingKey.Type
           exCodingKey.intValue == nil && exCodingKey.stringValue.contains(".") {
            let keys = exCodingKey.stringValue.split(separator: ".").map { ExCodingKey($0) }
            var container: Self? = self
            for key in keys.dropLast() {
                container = try? container?.nestedContainer(keyedBy: Self.Key, forKey: key as! Self.Key)
            }
            if let codingKey = keys.last,
               let value = container?.decodeIfPresent(codingKey as! Self.Key, as: type) {
                return value
            }
        }
        return nil
    }
}

// MARK: type-conversion

private extension KeyedDecodingContainer {
    
    func decodeIfTypeConvertible<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self) -> T? {
        if let value = try? decodeIfPresent(type, forKey: codingKey) {
            return value
        }
        
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
                    if let int = Int(string) {
                        return (int != 0) as? T
                    }
                    return nil
                }
            }
        }
        
        else if type is Int.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return Int(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return Int(string) as? T }
        }
        else if type is Int8.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return Int8(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int8(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return Int8(string) as? T }
        }
        else if type is Int16.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return Int16(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int16(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return Int16(string) as? T }
        }
        else if type is Int32.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return Int32(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int32(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return Int32(string) as? T }
        }
        else if type is Int64.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return Int64(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int64(double) as? T } // include Float
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return Int64(string) as? T }
        }
        else if type is UInt.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return UInt(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return UInt(string) as? T }
        }
        else if type is UInt8.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return UInt8(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return UInt8(string) as? T }
        }
        else if type is UInt16.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return UInt16(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return UInt16(string) as? T }
        }
        else if type is UInt32.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return UInt32(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return UInt32(string) as? T }
        }
        else if type is UInt64.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return UInt64(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return UInt64(string) as? T }
        }
        
        else if type is Double.Type {
            if let int64 = try? decodeIfPresent(Int64.self, forKey: codingKey) { return Double(int64) as? T } // include all Int types
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return Double(string) as? T }
        }
        else if type is Float.Type {
            if let int64 = try? decodeIfPresent(Int64.self, forKey: codingKey) { return Float(int64) as? T } // include all Int types
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) { return Float(string) as? T }
        }
        
        else if type is String.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) { return String(describing: bool) as? T }
            else if let int64 = try? decodeIfPresent(Int64.self, forKey: codingKey) { return String(describing: int64) as? T } // include all Int types
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return String(describing: double) as? T } // include Float
        }
        
        if let custom = self as? KeyedDecodingContainerCustomTypeConversion {
            return custom.decodeForTypeConversion(self, codingKey: codingKey, as: type)
        }
        
        return nil
    }
    
}

public protocol KeyedDecodingContainerCustomTypeConversion {
    func decodeForTypeConversion<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T?
}

// MARK: ExCodingKey

private struct ExCodingKey: CodingKey {
    
    public let stringValue: String
    public let intValue: Int?
    
    public init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    public init(_ stringValue: Substring) {
        self.init(String(stringValue))
    }
    public init?(stringValue: String) {
        self.init(stringValue)
    }
    
    public init(_ intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
    public init?(intValue: Int) {
        self.init(intValue)
    }
    
}

// MARK: - Encodable/Decodable and type-inference

// - seealso: [Codextended](https://github.com/JohnSundell/Codextended)

// Encodable.encode() -> Data?

public extension Encodable {
    
    func encoded(using encoder: DataEncoder = JSONEncoder()) -> Data? {
        return try? encoder.encode(self)
    }
    
    func encoded(using encoder: JSONEncoder = JSONEncoder()) -> [String: Any]? {
        if let data = encoded(using: encoder) as Data? {
            return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
        }
        return nil
    }
    
    func encoded(using encoder: JSONEncoder = JSONEncoder()) -> [Any]? {
        if let data = encoded(using: encoder) as Data? {
            return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [Any]
        }
        return nil
    }
    
    func encoded(using encoder: JSONEncoder = JSONEncoder()) -> String? {
        if let data = encoded(using: encoder) as Data? {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
}

// Decodable.decode(Data) -> Decodable?

public extension Decodable {
    
    static func decoded(from data: Data, using decoder: DataDecoder = JSONDecoder(), as type: Self.Type = Self.self) -> Self? {
        return try? decoder.decode(type, from: data)
    }
    
    static func decoded(from json: [String: Any], using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) -> Self? {
        if JSONSerialization.isValidJSONObject(json),
           let data = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed) {
            return try? decoder.decode(type, from: data)
        }
        return nil
    }
    
    static func decoded(from jsonArray: [Any], using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) -> Self? {
        if JSONSerialization.isValidJSONObject(jsonArray),
           let data = try? JSONSerialization.data(withJSONObject: jsonArray, options: .fragmentsAllowed) {
            return try? decoder.decode(type, from: data)
        }
        return nil
    }
    
    static func decoded(from string: String, using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) -> Self? {
        let data = Data(string.utf8)
        return try? decoder.decode(type, from: data)
    }
    
}

// Data.decode() -> Decodable?

public extension Data {
    func decoded<T: Decodable>(using decoder: DataDecoder = JSONDecoder(), as type: T.Type = T.self) -> T? {
        return try? decoder.decode(type, from: self)
    }
}

public extension Dictionary {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) -> T? {
        guard JSONSerialization.isValidJSONObject(self),
              let data = try? JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed) else {
            return nil
        }
        return data.decoded(using: decoder, as: type)
    }
}

public extension Array {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) -> T? {
        guard JSONSerialization.isValidJSONObject(self),
              let data = try? JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed) else {
            return nil
        }
        return data.decoded(using: decoder, as: type)
    }
}

public extension String {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) -> T? {
        return Data(self.utf8).decoded(using: decoder, as: type)
    }
}

// Method from JSON and PList Encoder
public protocol DataEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

// Method from JSON and PList Decoder
public protocol DataDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONEncoder: DataEncoder {}
extension JSONDecoder: DataDecoder {}

#if canImport(ObjectiveC) || swift(>=5.1)
extension PropertyListEncoder: DataEncoder {}
extension PropertyListDecoder: DataDecoder {}
#endif
