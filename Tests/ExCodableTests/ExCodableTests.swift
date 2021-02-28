//
//  ExCodableTests.swift
//  ExCodable
//
//  Created by Mr. Ming on 2021-02-10.
//  Copyright (c) 2021 Mr. Ming <minglq.9@gmail.com>. Released under the MIT license.
//

import XCTest

@testable
import ExCodable

// MARK: struct

struct TestStruct: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String = ""
}

extension TestStruct: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string")
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
    }
    
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
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
    }
    
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
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
    }
    
}

// MARK: type-adaption

struct TestTypeAdaption: Equatable {
    let boolFromInt, boolFromString: Bool?
    let intFromBool, intFromDouble, intFromString: Int?
    let uIntFromBool, uIntFromString: UInt?
    let doubleFromInt64, doubleFromString: Double?
    let floatFromInt64, floatFromString: Float?
    let stringFromBool, stringFromInt64, stringFromDouble: String?
}

extension TestTypeAdaption: Encodable, Decodable {
    
    enum Keys: String, CodingKey {
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

// MARK: custom type-adaption

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

struct TestCustomTypeAdaption: Equatable {
    var doubleFromBool: Double? = nil
}

extension TestCustomTypeAdaption: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.doubleFromBool, to: "doubleFromBool")
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
    }
    
}

// MARK: encode/decode-handler

struct TestHandlers: Equatable {
    var int: Int = 0
    var string: String = ""
}

extension TestHandlers: ExCodable {
    
    static var keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string", encode: { (encoder, stringKeys, test, keyPath) in
            encoder[stringKeys.first!] = "dddd" 
        }, decode: { (test, keyPath, decoder, stringKeys) in
            switch test.int {
                case 100: test.string = "Continue"
                case 200: test.string = "OK"
                case 304: test.string = "Not Modified"
                case 403: test.string = "Forbidden"
                case 404: test.string = "Not Found"
                case 418: test.string = "I'm a teapot"
                case 500: test.string = "Internal Server Error"
                case 200..<400: test.string = "success"
                default: test.string = "failure"
            }
        })
    ]
    
    init(from decoder: Decoder) throws {
        decode(with: Self.keyMapping, using: decoder)
    }
    func encode(to encoder: Encoder) throws {
        encode(with: Self.keyMapping, using: encoder)
    }
    
}

// MARK: - Tests

final class ExCodableTests: XCTestCase {
    
    func testStruct() {
        let test = TestStruct(int: 100, string: "Continue")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestStruct? {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testClass() {
        let test = TestClass(int: 200, string: "OK")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestClass? {
            XCTAssert(copy == test)
        }
        else {
            XCTFail()
        }
    }
    
    func testSubclass() {
        let test = TestSubclass(int: 304, string: "Not Modified", bool: true)
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestSubclass? {
            XCTAssert(copy == test)
        }
        else {
            XCTFail()
        }
    }
    
    func testSubscript() {
        let test = TestSubscript(int: 403, string: "Forbidden")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestSubscript? {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testAlternativeKeys() {
        let serverData = Data(#"{"i":404,"s":"Not Found"}"#.utf8)
        if let test = serverData.decoded() as TestAlternativeKeys?,
           let localData = test.encoded() as Data?,
           let copy = localData.decoded() as TestAlternativeKeys? {
            XCTAssertEqual(test, TestAlternativeKeys(int: 404, string: "Not Found"))
            XCTAssertEqual(copy, test)
            let localJSON: [String: Any] = (try? JSONSerialization.jsonObject(with: localData, options: .fragmentsAllowed)) as? [String: Any] ?? [:]
            XCTAssertEqual(NSDictionary(dictionary: localJSON), [
                "_is_local_": true,
                "int": 404,
                "string": "Not Found"
            ])
        }
        else {
            XCTFail()
        }
    }
    
    func testNestedKeys() {
        let test = TestNestedKeys(int: 418, string: "I'm a teapot")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestNestedKeys? {
            XCTAssertEqual(copy, test)
            let json: [String: Any] = (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)) as? [String: Any] ?? [:]
            debugPrint(json)
            XCTAssertEqual(NSDictionary(dictionary: json), [
                "int": 418,
                "nested": [
                    "string": "I'm a teapot"
                ]
            ])
        }
        else {
            XCTFail()
        }
    }
    
    func testTypeAdaption() {
        
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
        if let test = data.decoded() as TestTypeAdaption? {
            XCTAssertEqual(test, TestTypeAdaption(boolFromInt:      true,
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
        if let test2 = data2.decoded() as TestTypeAdaption? {
            XCTAssertEqual(test2, TestTypeAdaption(boolFromInt:      false,
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
    
    func testCustomTypeAdaption() {
        let data = Data(#"""
        {
            "doubleFromBool": true
        }
        """#.utf8)
        if let test = data.decoded() as TestCustomTypeAdaption? {
            XCTAssertEqual(test, TestCustomTypeAdaption(doubleFromBool: 1.0))
        }
        else {
            XCTFail()
        }
    }
    
    func testHandlers() {
        let test = TestHandlers(int: 500, string: "Internal Server Error")
        if let data = test.encoded() as Data?,
           let copy = data.decoded() as TestHandlers? {
            XCTAssertEqual(copy, test)
            let json: [String: Any] = (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)) as? [String: Any] ?? [:]
            debugPrint(json)
            XCTAssertEqual(NSDictionary(dictionary: json), [
                "int": 500,
                "string": "dddd"
            ])
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
            TestStruct(int: 500, string: "Internal Server Error")
        ]
        let dictionary = [
            "100": TestStruct(int: 100, string: "Continue"),
            "200": TestStruct(int: 200, string: "OK"),
            "304": TestStruct(int: 304, string: "Not Modified"),
            "403": TestStruct(int: 403, string: "Forbidden"),
            "404": TestStruct(int: 404, string: "Not Found"),
            "418": TestStruct(int: 418, string: "I'm a teapot"),
            "500": TestStruct(int: 500, string: "Internal Server Error")
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
        ("testStruct",          testStruct),
        ("testClass",           testClass),
        ("testSubclass",        testSubclass),
        ("testSubscript",       testSubscript),
        ("testAlternativeKeys", testAlternativeKeys),
        ("testNestedKeys",      testNestedKeys),
        ("testTypeAdaption",    testTypeAdaption),
        ("testCustomTypeAdaption", testCustomTypeAdaption),
        ("testHandlers",        testHandlers),
        ("testExCodable",       testExCodable)
    ]
    
}
