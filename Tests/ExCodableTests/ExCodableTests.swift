//
//  ExCodableTests.swift
//  ExCodable
//
//  Created by Mr. Ming on 2021-02-10.
//  Copyright (c) 2021 Mr. Ming <minglq.9@gmail.com>. Released under the MIT license.
//

import XCTest

// @testable
import ExCodable

// MARK: auto codable

struct TestAutoCodable: Codable, Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
    enum CodingKeys: String, CodingKey {
        case int = "i", string = "s"
    }
}

// MARK: manual codable

struct TestManualCodable: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
}

extension TestManualCodable: Codable {
    
    enum Keys: CodingKey {
        case int, i
        case nested, string
    }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: Keys.self) {
            if let int = (try? container.decodeIfPresent(Int.self, forKey: Keys.int))
                ?? (try? container.decodeIfPresent(Int.self, forKey: Keys.i)) {
                self.int = int
            }
            if let nestedContainer = try? container.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
               let string = try? nestedContainer.decodeIfPresent(String.self, forKey: Keys.string) {
                self.string = string
            }
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try? container.encodeIfPresent(int, forKey: Keys.int)
        var nestedContainer = container.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested)
        try? nestedContainer.encodeIfPresent(string, forKey: Keys.string)
    }
    
}

// MARK: struct

struct TestStruct: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
}

extension TestStruct: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string")
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
    }
    // func encode(to encoder: Encoder) throws {
    //     encode(with: Self.keyMapping, using: encoder)
    // }
    
}

// MARK: alternative-keys

struct TestAlternativeKeys: Equatable {
    var int: Int = 0
    var string: String = ""
}

extension TestAlternativeKeys: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string")
    ]
    
    static var keyMappingFromServer: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int", "i"),
        KeyMap(\.string, to: "string", "str", "s")
    ]
    
    enum LocalKeys: String {
        case isLocal = "_is_local_"
    }
    
    init(from decoder: Decoder) throws {
        let isLocal = decoder[LocalKeys.isLocal.rawValue] ?? false
        decode(with: isLocal ? Self.keyMapping : Self.keyMappingFromServer, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
        encoder[LocalKeys.isLocal.rawValue] = true
    }
    
}

// MARK: nested-keys

struct TestNestedKeys: Equatable {
    var int: Int = 0
    var string: String = ""
}

extension TestNestedKeys: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "nested.string")
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
    }
    // func encode(to encoder: Encoder) throws {
    //     encode(with: Self.keyMapping, using: encoder)
    // }
    
}

// MARK: custom encode/decode

struct TestCustomEncodeDecode: Equatable {
    var int: Int = 0
    var string: String?
}

extension TestCustomEncodeDecode: ExCodable {
    
    private enum Keys: CodingKey {
        case int, string
    }
    private static let dddd = "dddd"
    private func string(for int: Int) -> String {
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
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: Keys.int),
        KeyMap(\.string, to: Keys.string)
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
        if string == nil || string == Self.dddd {
            string = string(for: int)
        }
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
        encoder[Keys.string] = Self.dddd
    }
    
}

// MARK: let + subscripts + CodingKey, without default values

struct TestSubscript: Equatable {
    let int: Int
    let string: String
}

extension TestSubscript: Encodable, Decodable {
    
    enum Keys: CodingKey {
        case int, string
    }
    
    init(from decoder: Decoder) throws {
        int = decoder[Keys.int] ?? 0
        string = decoder[Keys.string] ?? ""
    }
    func encode(to encoder: Encoder) throws {
        encoder[Keys.int] = int
        encoder[Keys.string] = string
    }
    
}

// MARK: type-conversions

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
        boolFromInt = decoder[Keys.boolFromInt]
        boolFromString = decoder[Keys.boolFromString]
        intFromBool = decoder[Keys.intFromBool]
        intFromDouble = decoder[Keys.intFromDouble]
        intFromString = decoder[Keys.intFromString]
        uIntFromBool = decoder[Keys.uIntFromBool]
        uIntFromString = decoder[Keys.uIntFromString]
        doubleFromInt64 = decoder[Keys.doubleFromInt64]
        doubleFromString = decoder[Keys.doubleFromString]
        floatFromInt64 = decoder[Keys.floatFromInt64]
        floatFromString = decoder[Keys.floatFromString]
        stringFromBool = decoder[Keys.stringFromBool]
        stringFromInt64 = decoder[Keys.stringFromInt64]
        stringFromDouble = decoder[Keys.stringFromDouble]
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

extension KeyedDecodingContainer: KeyedDecodingContainerCustomTypeConversion {
    public func decodeForTypeConversion<T, K>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T? where T: Decodable, K: CodingKey {
        
        if type is Double.Type || type is Double?.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey as! Self.Key) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        
        else if type is Float.Type || type is Float?.Type {
            if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey as! Self.Key) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        
        return nil
    }
}

struct TestCustomTypeConversions: Equatable {
    var doubleFromBool: Double? = nil
}

extension TestCustomTypeConversions: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.doubleFromBool, to: "doubleFromBool")
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
    }
    // func encode(to encoder: Encoder) throws {
    //     encode(with: Self.keyMapping, using: encoder)
    // }
    
}

// MARK: class

class TestClass: ExCodable, Equatable {
    
    var int: Int = 0
    var string: String? = nil
    init(int: Int, string: String?) {
        (self.int, self.string) = (int, string)
    }
    
    static var keyMapping: [KeyMap<TestClass>] = [
        KeyMap(ref: \.int, to: "int"),
        KeyMap(ref: \.string, to: "string")
    ]
    
    required init(from decoder: Decoder) throws {
        decodeReference(with: Self.keyMapping, using: decoder)
    }
    // func encode(to encoder: Encoder) throws {
    //     encode(with: Self.keyMapping, using: encoder)
    // }
    
    static func == (lhs: TestClass, rhs: TestClass) -> Bool {
        return lhs.int == rhs.int && lhs.string == rhs.string
    }
}

// MARK: subclass

class TestSubclass: TestClass {
    var bool: Bool = false
    required init(int: Int, string: String, bool: Bool) {
        self.bool = bool
        super.init(int: int, string: string)
    }
    
    static var keyMappingForTestSubclass: [KeyMap<TestSubclass>] = [
        KeyMap(ref: \.bool, to: "bool")
    ]
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        decodeReference(with: Self.keyMappingForTestSubclass, using: decoder)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        encode(with: Self.keyMappingForTestSubclass, using: encoder)
    }
    
    static func == (lhs: TestSubclass, rhs: TestSubclass) -> Bool {
        return lhs.int == rhs.int
            && lhs.string == rhs.string
            && lhs.bool == rhs.bool
    }
}

// MARK: - Tests

final class ExCodableTests: XCTestCase {
    
    func testAutoCodable() {
        let test = TestAutoCodable(int: 100, string: "Continue")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestAutoCodable?,
           let json: [String: Any] = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(copy, test)
            XCTAssertEqual(NSDictionary(dictionary: json), ["i": 100, "s": "Continue"])
        }
        else {
            XCTFail()
        }
    }
    
    func testManualCodable() {
        let json = Data(#"{"i":200,"nested":{"string":"OK"}}"#.utf8)
        if let test = json.decoded() as TestManualCodable?,
           let data = test.encoded() as Data?,
           let copy = data.decoded() as TestManualCodable? {
            XCTAssertEqual(copy, test)
            XCTAssertEqual(data, Data(#"{"int":200,"nested":{"string":"OK"}}"#.utf8))
        }
        else {
            XCTFail()
        }
    }
    
    func testStruct() {
        let test = TestStruct(int: 304, string: "Not Modified")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestStruct? {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testAlternativeKeys() {
        let json = Data(#"{"i":403,"s":"Forbidden"}"#.utf8)
        if let test = json.decoded() as TestAlternativeKeys?,
           let data = test.encoded() as Data?,
           let copy = data.decoded() as TestAlternativeKeys? {
            XCTAssertEqual(test, TestAlternativeKeys(int: 403, string: "Forbidden"))
            XCTAssertEqual(copy, test)
            let localJSON: [String: Any] = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
            XCTAssertEqual(NSDictionary(dictionary: localJSON), [
                "_is_local_": true,
                "int": 403,
                "string": "Forbidden"
            ])
        }
        else {
            XCTFail()
        }
    }
    
    func testNestedKeys() {
        let test = TestNestedKeys(int: 404, string: "Not Found")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestNestedKeys? {
            XCTAssertEqual(copy, test)
            let json: [String: Any] = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
            debugPrint(json)
            XCTAssertEqual(NSDictionary(dictionary: json), [
                "int": 404,
                "nested": [
                    "string": "Not Found"
                ]
            ])
        }
        else {
            XCTFail()
        }
    }
    
    func testCustomEncodeDecode() {
        let test = TestCustomEncodeDecode(int: 418, string: "I'm a teapot")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestCustomEncodeDecode? {
            XCTAssertEqual(copy, test)
            let json: [String: Any] = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
            debugPrint(json)
            XCTAssertEqual(NSDictionary(dictionary: json), [
                "int": 418,
                "string": "dddd"
            ])
        }
        else {
            XCTFail()
        }
    }
    
    func testSubscript() {
        let test = TestSubscript(int: 500, string: "Internal Server Error")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestSubscript? {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testTypeConversions() {
        
        let data = Data(#"""
        {
            "boolFromInt":      123,
            "boolFromString":   "123",
            "intFromBool":      true,
            "intFromDouble":    12.3,
            "intFromString":    "123",
            "uIntFromBool":     true,
            "uIntFromString":   "123",
            "doubleFromInt64":  -123,
            "doubleFromString": "123",
            "floatFromInt64":   -123,
            "floatFromString":  "123",
            "stringFromBool":   true,
            "stringFromInt64":  -123,
            "stringFromDouble": 12.3
        }
        """#.utf8)
        if let test = data.decoded() as TestTypeConversions? {
            XCTAssertEqual(test, TestTypeConversions(boolFromInt:      true,
                                                  boolFromString:   true,
                                                  intFromBool:      1,
                                                  intFromDouble:    12,
                                                  intFromString:    123,
                                                  uIntFromBool:     1,
                                                  uIntFromString:   123,
                                                  doubleFromInt64:  -123.0,
                                                  doubleFromString: 123.0,
                                                  floatFromInt64:   -123.0,
                                                  floatFromString:  123.0,
                                                  stringFromBool:   "true",
                                                  stringFromInt64:  "-123",
                                                  stringFromDouble: "12.3"))
        }
        else {
            XCTFail()
        }
        
        let data2 = Data(#"""
        {
            "boolFromInt":      0,
            "boolFromString":   "abc",
            "intFromBool":      false,
            "intFromDouble":    12.3,
            "intFromString":    "",
            "uIntFromBool":     false,
            "uIntFromString":   "abc",
            "doubleFromInt64":  -123,
            "doubleFromString": "abc",
            "floatFromInt64":   -123,
            "floatFromString":  "abc",
            "stringFromBool":   false,
            "stringFromInt64":  -123,
            "stringFromDouble": 12.3
        }
        """#.utf8)
        if let test2 = data2.decoded() as TestTypeConversions? {
            XCTAssertEqual(test2, TestTypeConversions(boolFromInt:      false,
                                                   boolFromString:   nil,
                                                   intFromBool:      0,
                                                   intFromDouble:    12,
                                                   intFromString:    nil,
                                                   uIntFromBool:     0,
                                                   uIntFromString:   nil,
                                                   doubleFromInt64:  -123.0,
                                                   doubleFromString: nil,
                                                   floatFromInt64:   -123.0,
                                                   floatFromString:  nil,
                                                   stringFromBool:   "false",
                                                   stringFromInt64:  "-123",
                                                   stringFromDouble: "12.3"))
        }
        else {
            XCTFail()
        }
        
    }
    
    func testCustomTypeConversions() {
        let data = Data(#"""
        {
            "doubleFromBool": true
        }
        """#.utf8)
        if let test = data.decoded() as TestCustomTypeConversions? {
            XCTAssertEqual(test, TestCustomTypeConversions(doubleFromBool: 1.0))
        }
        else {
            XCTFail()
        }
    }
    
    func testClass() {
        let test = TestClass(int: 502, string: "Bad Gateway")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestClass? {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testSubclass() {
        let test = TestSubclass(int: 504, string: "Gateway Timeout", bool: true)
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestSubclass? {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testExCodable() {
        let array = [
            TestStruct(int: 100, string: "Continue"),
            TestStruct(int: 200, string: "OK"),
            TestStruct(int: 304, string: "Not Modified"),
            TestStruct(int: 403, string: "Forbidden"),
            TestStruct(int: 404, string: "Not Found"),
            TestStruct(int: 418, string: "I'm a teapot"),
            TestStruct(int: 500, string: "Internal Server Error"),
            TestStruct(int: 502, string: "Bad Gateway"),
            TestStruct(int: 504, string: "Gateway Timeout")
        ]
        let dictionary = [
            "100": TestStruct(int: 100, string: "Continue"),
            "200": TestStruct(int: 200, string: "OK"),
            "304": TestStruct(int: 304, string: "Not Modified"),
            "403": TestStruct(int: 403, string: "Forbidden"),
            "404": TestStruct(int: 404, string: "Not Found"),
            "418": TestStruct(int: 418, string: "I'm a teapot"),
            "500": TestStruct(int: 500, string: "Internal Server Error"),
            "502": TestStruct(int: 502, string: "Bad Gateway"),
            "504": TestStruct(int: 504, string: "Gateway Timeout")
        ]
        
        if let json = array.encoded() as Data?,
           let copies = json.decoded() as [TestStruct]?,
           let copies2 = [TestStruct].decoded(from: json) {
            XCTAssertEqual(copies, array)
            XCTAssertEqual(copies2, array)
        }
        else {
            XCTFail()
        }
        if let json = array.encoded() as [Any]?,
           let copies = json.decoded() as [TestStruct]?,
           let copies2 = [TestStruct].decoded(from: json) {
            XCTAssertEqual(copies, array)
            XCTAssertEqual(copies2, array)
        }
        else {
            XCTFail()
        }
        if let json = array.encoded() as String?,
           let copies = json.decoded() as [TestStruct]?,
           let copies2 = [TestStruct].decoded(from: json) {
            XCTAssertEqual(copies, array)
            XCTAssertEqual(copies2, array)
        }
        else {
            XCTFail()
        }
        
        if let json = dictionary.encoded() as Data?,
           let copies = json.decoded() as [String: TestStruct]?,
           let copies2 = [String: TestStruct].decoded(from: json) {
            XCTAssertEqual(copies, dictionary)
            XCTAssertEqual(copies2, dictionary)
        }
        else {
            XCTFail()
        }
        if let json = dictionary.encoded() as [String: Any]?,
           let copies = json.decoded() as [String: TestStruct]?,
           let copies2 = [String: TestStruct].decoded(from: json) {
            XCTAssertEqual(copies, dictionary)
            XCTAssertEqual(copies2, dictionary)
        }
        else {
            XCTFail()
        }
        if let json = dictionary.encoded() as String?,
           let copies = json.decoded() as [String: TestStruct]?,
           let copies2 = [String: TestStruct].decoded(from: json) {
            XCTAssertEqual(copies, dictionary)
            XCTAssertEqual(copies2, dictionary)
        }
        else {
            XCTFail()
        }
    }
    
    static var allTests = [
        ("testAutoCodable",     testAutoCodable),
        ("testManualCodable",   testManualCodable),
        ("testStruct",          testStruct),
        ("testAlternativeKeys", testAlternativeKeys),
        ("testNestedKeys",      testNestedKeys),
        ("testCustomEncodeDecode", testCustomEncodeDecode),
        ("testSubscript",       testSubscript),
        ("testTypeConversions", testTypeConversions),
        ("testCustomTypeConversions", testCustomTypeConversions),
        ("testClass",           testClass),
        ("testSubclass",        testSubclass),
        ("testExCodable",       testExCodable),
    ]
    
}
