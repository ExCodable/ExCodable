//
//  ExCodableFixtures.swift
//  ExCodable
//
//  Created by Míng on 2026-10-26.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import Foundation
import ExCodable

// let JSON: [String: any Codable] = [ "a": 1, "b": 2 ]
// 
// struct TestAnyCodable {
//     @ExCodableKey("json")
//     var json: [String: any Codable]? = nil
// }

// MARK: ExCodable

@ExCodable
struct TestExCodable: Equatable {
    @ExCodableKey
    let int: Int
    @ExCodableKey
    let string: String?
}

// MARK: auto codable

struct TestAutoCodable: Codable, Equatable {
    let int: Int
    let string: String?
    enum CodingKeys: String, CodingKey {
        case int = "i", string = "s"
    }
}

// MARK: manual codable

struct TestManualCodable: Equatable {
    let int: Int
    let string: String?
}

extension TestManualCodable: Codable {
    
    enum Keys: CodingKey {
        case int
        case nested, string, s
    }
    
    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: Keys.self)
        let int = try? container?.decodeIfPresent(Int.self, forKey: Keys.int)
        let string: String? = {
            if let nestedContainer = try? container?.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
               let nestedNestedContainer = try? nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
               let string = try? nestedNestedContainer.decodeIfPresent(String.self, forKey: Keys.string) {
                return string
            }
            else if let string = (try? container?.decodeIfPresent(String.self, forKey: Keys.string))
                        ?? (try? container?.decodeIfPresent(String.self, forKey: Keys.s)) {
                return string
            }
            else {
                return nil
            }
        }()
        self.init(int: int ?? 0, string: string)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try? container.encodeIfPresent(int, forKey: Keys.int)
        var nestedContainer = container.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested)
        var nestedNestedContainer = nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested)
        try? nestedNestedContainer.encodeIfPresent(string, forKey: Keys.string)
    }
}

// MARK: struct

@ExCodable
struct TestStruct: Equatable {
    @ExCodableKey("int")
    let int: Int
    @ExCodableKey("string")
    let string: String?
    var bool: Bool!
}

// MARK: struct with observers

@ExCodable
struct TestStructWithObservers: Equatable {
    @ExCodableKey
    var count: Int {
        willSet {}
        didSet {}
    }
    @ExCodableKey
    var name: String? {
        didSet {}
    }
}

// MARK: fixed let

@ExCodable
struct TestFixedLet: Equatable {
    let kind = "user"
    let role: String = "member"
    @ExCodableKey
    let id: Int
}

// MARK: struct with optional types

@ExCodable
struct TestStructWithOptionals: Equatable {
    @ExCodableKey("bool")
    var bool: Bool?
    @ExCodableKey("int")
    let int: Int?
    @ExCodableKey("int8")
    let int8: Int8?
    @ExCodableKey("int16")
    let int16: Int16?
    @ExCodableKey("int32")
    let int32: Int32?
    @ExCodableKey("int64")
    let int64: Int64?
    @ExCodableKey("uInt")
    let uInt: UInt?
    @ExCodableKey("uInt8")
    let uInt8: UInt8?
    @ExCodableKey("uInt16")
    let uInt16: UInt16?
    @ExCodableKey("uInt32")
    let uInt32: UInt32?
    @ExCodableKey("uInt64")
    let uInt64: UInt64?
    @ExCodableKey("double")
    let double: Double?
    @ExCodableKey("float")
    let float: Float?
    @ExCodableKey("float16")
    let float16: Float16?
    @ExCodableKey("float32")
    let float32: Float32?
    @ExCodableKey("float64")
    let float64: Float64?
    @ExCodableKey("string")
    let string: String?
}

// MARK: struct with enum

enum TestEnum: Int, Codable {
    case zero = 0, one = 1
}

@ExCodable
struct TestStructWithEnum: Equatable {
    @ExCodableKey
    let `enum`: TestEnum
}

@ExCodable
struct TestStructWithOptionalEnum: Equatable {
    @ExCodableKey
    let `enum`: TestEnum?
}

// MARK: alternative-keys

@ExCodable
struct TestAlternativeKeys: Equatable {
    @ExCodableKey("int", "i")
    let int: Int
    @ExCodableKey("string", "str", "s")
    let string: String!
}

// MARK: nested-keys

@ExCodable
struct TestNestedKeys: Equatable {
    @ExCodableKey
    let int: Int
    @ExCodableKey("nested.nested.string")
    let string: String!
}

@ExCodable
struct TestNestedSiblings: Equatable {
    @ExCodableKey("user.name")
    let name: String
    @ExCodableKey("user.role")
    let role: String
}

// !!!: NOT supported
// @ExCodable
// struct TestDotPathPrefixClash: Equatable {
//     @ExCodableKey("user")
//     let user: String
//     @ExCodableKey("user.name")
//     let name: String
// }

@ExCodable
struct TestDotPathPrefixClashUser: Equatable {
    @ExCodableKey
    let id: Int
}

@ExCodable
struct TestDotPathPrefixClash: Equatable {
    @ExCodableKey("user")
    let user: TestDotPathPrefixClashUser
    @ExCodableKey("user.name")
    let name: String
}

@ExCodable
struct TestDotPathEmpty: Equatable {
    @ExCodableKey("..")
    let value: String
}

@ExCodable
struct TestDotPathTrailing: Equatable {
    @ExCodableKey("user.")
    let name: String
}

@ExCodable
struct TestDotPathRepeated: Equatable {
    @ExCodableKey("a..b")
    let name: String
}

// MARK: custom encoding/decoding

fileprivate func message(for int: Int) -> String {
    switch int {
        case 100: return "Continue"
        case 200: return "OK"
        case 304: return "Not Modified"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 418: return "I'm a teapot"
        case 500: return "Internal Server Error"
        case 200..<400: return "success"
        default: return "failure"
    }
}

@ExCodable
struct TestCustomEncodeDecode: Equatable {
    
    @ExCodableKey(encode: { encoder, value in
        encoder["int"] = value <= 0 ? 0 : value
    }, decode: { decoder in
        if let int: Int = decoder["int"], int > 0 {
            return int
        }
        return 0
    })
    let int: Int
    
    @ExCodableKey(encode: { encoder, value in
        encoder["nested.nested.string"] = "<placeholder>"
    }, decode: { decoder in
        if let string: String = decoder["nested.nested.string"],
           string != "<placeholder>" {
            return string
        }
        if let int: Int = decoder["int"] {
            return message(for: int)
        }
        return nil
    })
    let string: String?
    
    @ExCodableKey(
        encode: { encoder, value in encoder["bool"] = value },
        decode: { decoder -> Bool? in return decoder["bool"/*, converter: Self.self*/] }
    )
    let bool: Bool
}

// MARK: let + subscripts + CodingKey, without default values

struct TestSubscript: Equatable {
    let int: Int
    let string: String
}

extension TestSubscript: Codable {
    
    enum Keys: CodingKey {
        case int, string
    }
    
    init(from decoder: Decoder) throws {
        // - seealso:
        // string = decoder.decode(Keys.string, as: String.self, converter: Self.self)!
        // string = try decoder.decodeThrows(Keys.string, as: String.self, converter: Self.self)!
        // string = try decoder.decodeNonnullThrows(Keys.string, as: String.self, converter: Self.self)
        int = decoder[Keys.int/*, converter: Self.self*/] ?? 0
        string = decoder[Keys.string/*, converter: Self.self*/] ?? ""
    }
    func encode(to encoder: Encoder) throws {
        // - seealso:
        // encoder.encode(string, for: Keys.string)
        // try encoder.encodeThrows(string, for: Keys.string)
        // try encoder.encodeNonnullThrows(string, for: Keys.string)
        encoder[Keys.int] = int
        encoder[Keys.string] = string
    }
}

// MARK: integer range

@ExCodable
struct TestIntegerRange: Equatable {
    @ExCodableKey
    let int8: Int8?
    @ExCodableKey
    let uInt8: UInt8?
    @ExCodableKey
    let uInt64: UInt64?
}

// MARK: type-conversions

@ExCodable
struct TestTypeConversion: Equatable {
    @ExCodableKey
    let intFromString: Int?
    @ExCodableKey
    let stringFromInt: String???
}

struct TestTypeConversions: Equatable {
    let boolFromInt, boolFromString: Bool?
    let intFromBool, intFromDouble, intFromString: Int?
    let uIntFromBool, uIntFromString: UInt?
    let doubleFromInt64, doubleFromString: Double?
    let floatFromInt64, floatFromString: Float?
    let stringFromBool, stringFromInt64, stringFromDouble: String?
}

extension TestTypeConversions: Encodable, Decodable {
    
    enum Keys: CodingKey {
        case boolFromInt, boolFromString
        case intFromBool, intFromDouble, intFromString
        case uIntFromBool, uIntFromString
        case doubleFromInt64, doubleFromString
        case floatFromInt64, floatFromString
        case stringFromBool, stringFromInt64, stringFromDouble
    }
    
    init(from decoder: Decoder) throws {
        boolFromInt = decoder[Keys.boolFromInt/*, converter: Self.self*/]
        boolFromString = decoder[Keys.boolFromString/*, converter: Self.self*/]
        intFromBool = decoder[Keys.intFromBool/*, converter: Self.self*/]
        intFromDouble = decoder[Keys.intFromDouble/*, converter: Self.self*/]
        intFromString = decoder[Keys.intFromString/*, converter: Self.self*/]
        uIntFromBool = decoder[Keys.uIntFromBool/*, converter: Self.self*/]
        uIntFromString = decoder[Keys.uIntFromString/*, converter: Self.self*/]
        doubleFromInt64 = decoder[Keys.doubleFromInt64/*, converter: Self.self*/]
        doubleFromString = decoder[Keys.doubleFromString/*, converter: Self.self*/]
        floatFromInt64 = decoder[Keys.floatFromInt64/*, converter: Self.self*/]
        floatFromString = decoder[Keys.floatFromString/*, converter: Self.self*/]
        stringFromBool = decoder[Keys.stringFromBool/*, converter: Self.self*/]
        stringFromInt64 = decoder[Keys.stringFromInt64/*, converter: Self.self*/]
        stringFromDouble = decoder[Keys.stringFromDouble/*, converter: Self.self*/]
    }
    
    func encode(to encoder: Encoder) throws {
        encoder[Keys.boolFromInt] = boolFromInt
        encoder[Keys.boolFromString] = boolFromString
        encoder[Keys.intFromBool] = intFromBool
        encoder[Keys.intFromDouble] = intFromDouble
        encoder[Keys.intFromString] = intFromString
        encoder[Keys.uIntFromBool] = uIntFromBool
        encoder[Keys.uIntFromString] = uIntFromString
        encoder[Keys.doubleFromInt64] = doubleFromInt64
        encoder[Keys.doubleFromString] = doubleFromString
        encoder[Keys.floatFromInt64] = floatFromInt64
        encoder[Keys.floatFromString] = floatFromString
        encoder[Keys.stringFromBool] = stringFromBool
        encoder[Keys.stringFromInt64] = stringFromInt64
        encoder[Keys.stringFromDouble] = stringFromDouble
    }
}

// MARK: custom type-conversions

@ExCodable
struct TestCustomTypeConverter: Equatable {
    @ExCodableKey
    let doubleFromBool: Double?
    @ExCodableKey
    let boolFromDouble: Bool?
}

extension TestCustomTypeConverter: ExCodableDecodingTypeConverter {
    public static func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T? {
        
        // for nested optionals, e.g. `var int: Int??? = nil`
        let wrappedType = T?.wrappedType
        
        // decode Double from Bool
        if type is Double.Type || wrappedType is Double.Type {
            if let bool = try? container.decodeIfPresent(Bool.self, forKey: codingKey) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        // decode Float from Bool
        else if type is Float.Type || wrappedType is Float.Type {
            if let bool = try? container.decodeIfPresent(Bool.self, forKey: codingKey) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        
        return nil
    }
}

extension ExCodableGlobalDecodingTypeConverter: ExCodableDecodingTypeConverter {
    public static func decode<T: Decodable, _K: CodingKey>(_ container: KeyedDecodingContainer<_K>, codingKey: _K, as type: T.Type) -> T? {
        
        // for nested optionals, e.g. `var int: Int??? = nil`
        let wrappedType = T?.wrappedType
        
        // decode Bool from Double
        if type is Bool.Type || wrappedType is Bool.Type {
            if let double = try? container.decodeIfPresent(Double.self, forKey: codingKey) {
                return (double != 0) as? T
            }
        }
        
        return nil
    }
}

// MARK: class

@ExCodable
class TestClass {
    @ExCodableKey
    let int: Int
    @ExCodableKey
    let string: String?
    
    required init() {
        (self.int, self.string) = (0, nil)
    }
    init(int: Int, string: String?) {
        (self.int, self.string) = (int, string)
    }
    
    static func == (lhs: TestClass, rhs: TestClass) -> Bool {
        return lhs.int == rhs.int && lhs.string == rhs.string
    }
}

extension TestClass: Equatable {}

// MARK: subclass

@ExCodable
class TestSubclass: TestClass {
    
    @ExCodableKey
    let bool: Bool
    
    required init() {
        self.bool = false
        super.init()
    }
    required init(int: Int, string: String, bool: Bool) {
        self.bool = bool
        super.init(int: int, string: string)
    }
    
    static func == (lhs: TestSubclass, rhs: TestSubclass) -> Bool {
        return (lhs.int == rhs.int
                && lhs.string == rhs.string
                && lhs.bool == rhs.bool)
    }
}

// MARK: explicit Codable and generics

@ExCodable
struct TestExplicitCodable: Codable, Equatable {
    @ExCodableKey
    let id: Int
}

@ExCodable
struct TestGenericBox<T: Codable> {
    @ExCodableKey
    let value: T
}

@ExCodable
struct TestFreeGeneric<T> {
    @ExCodableKey
    let value: T
}

@ExCodable
struct TestPartialGeneric<A: Codable, B> {
    @ExCodableKey
    let a: A
    @ExCodableKey
    let b: B
}

@ExCodable
class TestGenericClass<T> {
    @ExCodableKey
    let value: T
    init(value: T) { self.value = value }
}

// MARK: default

@ExCodable
struct TestDefault: Equatable {
    @ExCodableKey("int", default: 0)
    let int: Int
    @ExCodableKey("string", default: "default")
    let string: String
}

// MARK: nonnull and `throws`

@ExCodable
struct TestNonnull: Equatable {
    @ExCodableKey("int", nonnull: true)
    let nonnullInt: Int!
}

@ExCodable
struct TestNestedNonnull: Equatable {
    @ExCodableKey("nested.int", "int", nonnull: true)
    let nonnullInt: Int!
}

@ExCodable
struct TestThrows: Equatable {
    @ExCodableKey("string", "nested.string", throws: true)
    let throwsString: String!
}

@ExCodable
struct TestNestedThrows: Equatable {
    @ExCodableKey("nested.string", "string", throws: true)
    let throwsString: String!
}

@ExCodable
struct TestNonnullWithThrows: Equatable {
    @ExCodableKey("throws", nonnull: true)
    let testThrows: TestThrows!
}
