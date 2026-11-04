//
//  FeatureFixtures.swift
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
        let string: String? =
        if let nestedContainer = try? container?.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
           let nestedNestedContainer = try? nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
           let string = try? nestedNestedContainer.decodeIfPresent(String.self, forKey: Keys.string) {
            string
        }
        else if let string = (try? container?.decodeIfPresent(String.self, forKey: Keys.string))
                    ?? (try? container?.decodeIfPresent(String.self, forKey: Keys.s)) {
            string
        }
        else {
            nil
        }
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

/// Records property-observer calls so tests can assert they did or did not run.
final class TestObserverLog: @unchecked Sendable {
    static let shared = TestObserverLog()
    private(set) var events: [String] = []
    func record(_ event: String) { events.append(event) }
    func reset() { events.removeAll() }
}

@ExCodable
struct TestStructWithObservers: Equatable {
    @ExCodableKey
    var count: Int {
        willSet { TestObserverLog.shared.record("count.willSet:\(newValue)") }
        didSet { TestObserverLog.shared.record("count.didSet:\(count)") }
    }
    @ExCodableKey
    var name: String? {
        didSet { TestObserverLog.shared.record("name.didSet:\(String(describing: name))") }
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
    return switch int {
        case 100: "Continue"
        case 200: "OK"
        case 304: "Not Modified"
        case 403: "Forbidden"
        case 404: "Not Found"
        case 418: "I'm a teapot"
        case 500: "Internal Server Error"
        case 200..<400: "success"
        default: "failure"
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
        else if let int: Int = decoder["int"] {
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
        int = decoder[Keys.int/*, converter: Self.self*/] ?? 0
        string = decoder[Keys.string/*, converter: Self.self*/] ?? ""
    }
    func encode(to encoder: Encoder) throws {
        // - seealso:
        // encoder.encode(string, for: Keys.string)
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
    @ExCodableKey("int", default: 1)
    let int: Int
    @ExCodableKey("int2")
    var int2: Int = 2
    @ExCodableKey("string", default: "default")
    let string: String
}

/// Every kind of property initializer that can act as a default value when decode failed.
@ExCodable
struct TestInitialDefaultValue: Equatable {
    @ExCodableKey("int8")
    var int8: Int8 = 8
    @ExCodableKey("uint")
    var uint: UInt = 1
    @ExCodableKey("double")
    var double: Double = 2.5
    @ExCodableKey("float16")
    var float16: Float16 = 2.5
    @ExCodableKey("bool")
    var bool: Bool = true
    @ExCodableKey("string")
    var string: String = "initial"
    @ExCodableKey("url")
    var url: URL = URL(string: "https://initial.example")!
    @ExCodableKey("uuid")
    var uuid: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    @ExCodableKey("array")
    var array: [Int] = [1, 2]
    @ExCodableKey("dictionary")
    var dictionary: [String: Int] = ["a": 1]
    @ExCodableKey("enum")
    var `enum`: TestEnum = .one
    @ExCodableKey("nested")
    var nested: TestNestedValue = TestNestedValue(x: 9)
    @ExCodableKey("optional")
    var optional: Int? = 5
}

/// Used only through `TestInitialDefaultValue`; failure of any field must fall back whole.
struct TestNestedValue: Codable, Equatable {
    var x: Int
}

/// Same shape without initializers: a failed decode must throw instead of falling back.
@ExCodable
struct TestNoInitialValue: Equatable {
    @ExCodableKey("array")
    var array: [Int]
}

/// A non-optional property reports a missing or null value even though an initial value exists.
@ExCodable
struct TestInitialValueRequired: Equatable {
    @ExCodableKey("int")
    var int: Int = 2
}


// MARK: allKeys

/// `@ExCodable` and `@ExCodable(.exCodableKeys)` must behave identically. `unmarked` really is
/// unmarked here, and `.exCodableKeys` leaves it out of coding.
@ExCodable
struct TestExCodableKeysDefault: Equatable {
    @ExCodableKey
    var key: Int
    var unmarked: Int = 0
}

/// Same shape as `TestExCodableKeysDefault` with the option spelled out.
@ExCodable(.exCodableKeys)
struct TestExCodableKeysExplicit: Equatable {
    @ExCodableKey
    var key: Int
    var unmarked: Int = 0
}

@ExCodable(.allKeys)
struct TestAllKeys: Equatable {
    var int: Int
    var string: String
}

/// `.allKeys` codes every stored property; only `@ExCodableExcept` opts one out.
@ExCodable(.allKeys)
struct TestAllKeysWithExcept: Equatable {
    var kept: Int
    @ExCodableExcept
    var excluded: String = "initial"
    /// A second property with an initial value, also coded implicitly.
    var extra: Int = 7
}

/// Same shape as `TestAllKeysWithExcept`, but every coded property names `@ExCodableKey`
/// explicitly, to prove the two spellings are interchangeable.
@ExCodable(.allKeys)
struct TestAllKeysWithExceptExplicit: Equatable {
    @ExCodableKey
    var kept: Int
    @ExCodableExcept
    var excluded: String = "initial"
    @ExCodableKey
    var extra: Int = 7
}

@ExCodable(.allKeys)
struct TestAllKeysWithExplicitKey: Equatable {
    /// No `@ExCodableKey`: still coded, because `.allKeys` includes every stored property.
    var unmarked: Int
    /// Explicit key with its own name and parameters; those win over the `allKeys` default.
    @ExCodableKey("renamed")
    var renamedFrom: String
}

@ExCodable(.allKeys)
struct TestAllKeysWithFixedLet: Equatable {
    let kind = "user"
    var value: Int
}

@ExCodable(.allKeys)
class TestAllKeysClass {
    var int: Int = 0
    @ExCodableExcept
    var excluded: String = "initial"
}

/// Module-qualified spelling of the same option; must behave exactly like `.allKeys`.
@ExCodable(ExCodableOptions.allKeys)
struct TestAllKeysQualified: Equatable {
    var int: Int
}

/// `.exCodableKeys` + `@ExCodableExcept`: the attribute is a no-op and warns, but the type still
/// compiles and behaves exactly as if the attribute were absent.
@ExCodable
struct TestExceptInExCodableKeys: Equatable {
    @ExCodableKey
    var key: Int
    @ExCodableExcept
    var excluded: Int = 3
}

/// Keys containing characters that need escaping in a Swift string literal.
@ExCodable
struct TestEscapedKeys: Equatable {
    @ExCodableKey("has\"quote")
    var quote: Int
    @ExCodableKey("has\\backslash")
    var backslash: Int
    @ExCodableKey("has\ttab")
    var tab: Int
    @ExCodableKey("has\nnewline")
    var newline: Int
}

// MARK: optional and strictType

/// The four combinations of optionality and `strictType`, used to pin down which error each
/// case reports. `Required` means "declared non-optional", so a missing value must fail.
@ExCodable
struct TestMatrixRequiredPermissive: Equatable {
    @ExCodableKey("v")
    var v: Int
}

@ExCodable
struct TestMatrixRequiredStrict: Equatable {
    @ExCodableKey("v", strictType: true)
    var v: Int
}

@ExCodable
struct TestMatrixOptionalPermissive: Equatable {
    @ExCodableKey("v")
    var v: Int?
}

@ExCodable
struct TestMatrixOptionalStrict: Equatable {
    @ExCodableKey("v", strictType: true)
    var v: Int?
}

@ExCodable
struct TestRequired: Equatable {
    @ExCodableKey("int")
    let requiredInt: Int!
}

@ExCodable
struct TestNestedRequired: Equatable {
    @ExCodableKey("nested.int", "int")
    let requiredInt: Int!
}

@ExCodable
struct TestStrictType: Equatable {
    @ExCodableKey("string", "nested.string", strictType: true)
    let strictTypeString: String!
}

@ExCodable
struct TestNestedStrictType: Equatable {
    @ExCodableKey("nested.string", "string", strictType: true)
    let strictTypeString: String!
}

@ExCodable
struct TestRequiredAndStrictType: Equatable {
    @ExCodableKey("throws")
    let testStrictType: TestStrictType!
}

@MainActor
@ExCodable
struct TestMainActorStruct: Equatable {
    @ExCodableKey
    var int: Int
    @ExCodableKey("string")
    var string: String?
}

@MainActor
@ExCodable
class TestMainActorClass {
    @ExCodableKey
    var int: Int
}

@MainActor
@ExCodable
class TestMainActorSubclass: TestMainActorClass {
    @ExCodableKey
    var string: String?
}

/// An attributed first inherited type is a protocol, never a superclass.
@ExCodable
final class TestUncheckedSendableClass: @unchecked Sendable {
    @ExCodableKey
    var int: Int
}

@ExCodable
final class TestAnyInheritedClass: CustomStringConvertible, @unchecked Sendable {
    @ExCodableKey
    var int: Int
    var description: String { "\(int)" }
}

/// Collections and `Date` have no builtin element conversion. A `decode` closure does it.
@ExCodable
struct TestCollectionConversion: Equatable {
    @ExCodableKey(decode: { decoder -> [Int]? in
        // ["1", "2"] or [1, 2]
        if let strings: [String] = decoder["ints"] {
            return strings.compactMap { Int($0) }
        }
        return decoder["ints"]
    })
    let ints: [Int]
    
    @ExCodableKey(decode: { decoder -> [String: Int]? in
        // {"a": "1"} or {"a": 1}
        if let strings: [String: String] = decoder["scores"] {
            return strings.compactMapValues { Int($0) }
        }
        return decoder["scores"]
    })
    let scores: [String: Int]
    
    @ExCodableKey(encode: { encoder, date in
        encoder["date"] = ISO8601DateFormatter().string(from: date)
    }, decode: { decoder -> Date? in
        // seconds since 1970 or "2026-11-04T12:00:00Z"
        // Check the number first: the builtin conversion also turns a number into a string.
        if let seconds: Double = decoder["date"] {
            return Date(timeIntervalSince1970: seconds)
        }
        if let string: String = decoder["date"] {
            return ISO8601DateFormatter().date(from: string)
        }
        return nil
    })
    let date: Date
}

/// A `decode` closure that returns `nil` for a required property throws instead of crashing.
@ExCodable
struct TestCustomDecodeReturnsNil {
    @ExCodableKey(decode: { _ -> Int? in nil })
    let required: Int
    @ExCodableKey(decode: { _ -> Int? in nil })
    let optional: Int?
    @ExCodableKey(default: 7, decode: { _ -> Int? in nil })
    let defaulted: Int
}

/// A required property that is nil throws before the custom `encode` closure runs.
@ExCodable
struct TestCustomEncodeNilRequired {
    @ExCodableKey(encode: { (encoder: Encoder, value: Int!) in
        encoder["required"] = value
    })
    var required: Int!
}

/// A custom `encode` closure may open any container, not only a keyed one.
@ExCodable
struct TestCustomEncodeSingleValueContainer {
    @ExCodableKey(encode: { (encoder: Encoder, value: String) in
        var container = encoder.singleValueContainer()
        try container.encode(value)
    })
    var value: String
}

@ExCodable
struct TestCustomEncodeUnkeyedContainer {
    @ExCodableKey(encode: { (encoder: Encoder, value: [Int]) in
        var container = encoder.unkeyedContainer()
        for element in value {
            try container.encode(element)
        }
    })
    var value: [Int]
}

// MARK: an enum value that is not a case

enum TestStringEnum: String, Codable {
    case one, two
}

@ExCodable struct TestEnumRequired { @ExCodableKey var v: TestEnum }
@ExCodable struct TestEnumRequiredStrict { @ExCodableKey(strictType: true) var v: TestEnum }
@ExCodable struct TestEnumOptional { @ExCodableKey var v: TestEnum? }
@ExCodable struct TestEnumOptionalStrict { @ExCodableKey(strictType: true) var v: TestEnum? }
@ExCodable struct TestEnumDefault { @ExCodableKey(default: TestEnum.one) var v: TestEnum }

@ExCodable struct TestStringEnumRequired { @ExCodableKey var v: TestStringEnum }
@ExCodable struct TestStringEnumRequiredStrict { @ExCodableKey(strictType: true) var v: TestStringEnum }
@ExCodable struct TestStringEnumOptional { @ExCodableKey var v: TestStringEnum? }
@ExCodable struct TestStringEnumOptionalStrict { @ExCodableKey(strictType: true) var v: TestStringEnum? }
@ExCodable struct TestStringEnumDefault { @ExCodableKey(default: TestStringEnum.one) var v: TestStringEnum }

// MARK: a nested key reports the error of the value, not of the missing path

@ExCodable struct TestNestedEnumRequired { @ExCodableKey("a.b") var v: TestEnum }
@ExCodable struct TestNestedEnumOptionalStrict { @ExCodableKey("a.b", strictType: true) var v: TestEnum? }
@ExCodable struct TestNestedStringRequired { @ExCodableKey("a.b") var v: String }
@ExCodable struct TestNestedAlternativeKeys { @ExCodableKey("x.y", "a.b") var v: TestEnum }
