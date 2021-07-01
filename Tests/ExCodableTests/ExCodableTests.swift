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
    @ExCodable("int")
    private(set) var int: Int = 0
    @ExCodable("string")
    private(set) var string: String? = nil
    var bool: Bool!
}
extension TestStruct: ExAutoCodable {}

// MARK: alternative-keys & alternative-keyMapping

struct TestAlternativeKeys: Equatable {
    @ExCodable("int", "i")
    var int: Int = 0
    @ExCodable("string", "str", "s")
    var string: String! = nil
}
extension TestAlternativeKeys: ExAutoCodable {}

// MARK: nested-keys

struct TestNestedKeys: Equatable {
    @ExCodable
    var int: Int = 0
    @ExCodable("nested.string")
    var string: String! = nil
}
extension TestNestedKeys: ExAutoCodable {}

// MARK: custom encode/decode

struct TestCustomEncodeDecode: Equatable {
    @ExCodable(Keys.int)
    var int: Int = 0
    var string: String?
    @ExCodable(encode: { encoder, value in
        encoder[Keys.bool] = value
    }, decode: { decoder in
        return decoder[Keys.bool]
    })
    var bool: Bool = false
}

extension TestCustomEncodeDecode: Codable {
    
    private enum Keys: CodingKey {
        case int, string, bool
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
    
    init(from decoder: Decoder) throws {
        try decode(from: decoder, nonnull: false, throws: false)
        string = decoder[Keys.string]
        if string == nil || string == Self.dddd {
            string = string(for: int)
        }
    }
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, nonnull: false, throws: false)
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
        // - seealso:
        // string = decoder.decode(<#T##codingKeys: CodingKey...##CodingKey#>)
        // string = try decoder.decodeThrows(<#T##codingKeys: CodingKey...##CodingKey#>)
        // string = try decoder.decodeNonnullThrows(<#T##codingKeys: CodingKey...##CodingKey#>)
        int = decoder[Keys.int] ?? 0
        string = decoder[Keys.string] ?? ""
    }
    func encode(to encoder: Encoder) throws {
        // - seealso:
        // encoder.encode(<#T##value: Encodable?##Encodable?#>, for: <#T##CodingKey#>)
        // try encoder.encodeThrows(<#T##value: Encodable?##Encodable?#>, for: <#T##CodingKey#>)
        // try encoder.encodeNonnullThrows(<#T##value: Encodable##Encodable#>, for: <#T##CodingKey#>)
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

// @available(*, deprecated)
// extension KeyedDecodingContainer: KeyedDecodingContainerCustomTypeConversion {
//     public func decodeForTypeConversion<T, K>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T? where T: Decodable, K: CodingKey {
//         
//         if type is Double.Type || type is Double?.Type {
//             if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey as! Self.Key) {
//                 return (bool ? 1.0 : 0.0) as? T
//             }
//         }
//         
//         else if type is Float.Type || type is Float?.Type {
//             if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey as! Self.Key) {
//                 return (bool ? 1.0 : 0.0) as? T
//             }
//         }
//         
//         return nil
//     }
// }

struct FloatToBoolDecodingTypeConverter: ExCodableDecodingTypeConverter {
    public func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) -> T? {
        // Bool -> Double
        if type is Double.Type || type is Double?.Type {
            if let bool = try? container.decodeIfPresent(Bool.self, forKey: codingKey) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        // Bool -> Float
        else if type is Float.Type || type is Float?.Type {
            if let bool = try? container.decodeIfPresent(Bool.self, forKey: codingKey) {
                return (bool ? 1.0 : 0.0) as? T
            }
        }
        // Double or Float NOT found
        return nil
    }
}

struct TestCustomTypeConverter: Equatable {
    @ExCodable("doubleFromBool")
    var doubleFromBool: Double? = nil
}
extension TestCustomTypeConverter: ExAutoCodable {}

// MARK: class

class TestClass: Codable, Equatable {
    
    @ExCodable("int")
    var int: Int = 0
    @ExCodable("string")
    var string: String? = nil
    init(int: Int, string: String?) {
        (self.int, self.string) = (int, string)
    }
    
    required init(from decoder: Decoder) throws {
        try decode(from: decoder, nonnull: false, throws: false)
    }
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, nonnull: false, throws: false)
    }
    
    static func == (lhs: TestClass, rhs: TestClass) -> Bool {
        return lhs.int == rhs.int && lhs.string == rhs.string
    }
}

// MARK: subclass

class TestSubclass: TestClass {
    
    @ExCodable("bool")
    var bool: Bool = false
    required init(int: Int, string: String, bool: Bool) {
        self.bool = bool
        super.init(int: int, string: string)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    static func == (lhs: TestSubclass, rhs: TestSubclass) -> Bool {
        return lhs.int == rhs.int
            && lhs.string == rhs.string
            && lhs.bool == rhs.bool
    }
}

// MARK: ExCodable

struct TestExCodable: Equatable {
    @ExCodable("int")
    private(set) var int: Int = 0
    @ExCodable("string")
    private(set) var string: String? = nil
}
extension TestExCodable: ExAutoCodable {}

// MARK: - Tests

final class ExCodableTests: XCTestCase {
    
    func testAutoCodable() {
        let test = TestAutoCodable(int: 100, string: "Continue")
        if let data = try? test.encoded() as Data,
           let copy = try? data.decoded() as TestAutoCodable,
           let json: [String: Any] = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(copy, test)
            XCTAssertEqual(NSDictionary(dictionary: json), ["i": 100, "s": "Continue"])
        }
        else {
            XCTFail()
        }
    }
    
    func testManualCodable() {
        let json = Data(#"{"int":200,"nested":{"string":"OK"}}"#.utf8)
        if let test = try? json.decoded() as TestManualCodable,
           let data = try? test.encoded() as Data,
           let copy = try? data.decoded() as TestManualCodable {
            XCTAssertEqual(copy, test)
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            XCTAssertEqual(NSDictionary(dictionary: json), ["int":200,"nested":["string":"OK"]])
        }
        else {
            XCTFail()
        }
    }
    
    func testStruct() {
        let test = TestStruct(int: 304, string: "Not Modified")
        if let data = try? test.encoded() as Data,
           let copy1 = try? data.decoded() as TestStruct,
           let copy2 = try? TestStruct.decoded(from: data) {
            XCTAssertEqual(copy1, test)
            XCTAssertEqual(copy2, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testAlternativeKeys() {
        let json = Data(#"{"i":403,"s":"Forbidden"}"#.utf8)
        if let test = try? json.decoded() as TestAlternativeKeys,
           let data = try? test.encoded() as Data,
           let copy = try? data.decoded() as TestAlternativeKeys {
            XCTAssertEqual(test, TestAlternativeKeys(int: 403, string: "Forbidden"))
            XCTAssertEqual(copy, test)
            let localJSON = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            XCTAssertEqual(NSDictionary(dictionary: localJSON), [
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
        if let data = try? test.encoded() as Data,
           let copy = try? data.decoded() as TestNestedKeys {
            XCTAssertEqual(copy, test)
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
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
        let test = TestCustomEncodeDecode(int: 418, string: "I'm a teapot", bool: true)
        if let data = try? test.encoded() as Data,
           let copy = try? data.decoded() as TestCustomEncodeDecode {
            XCTAssertEqual(copy, test)
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            debugPrint(json)
            XCTAssertEqual(NSDictionary(dictionary: json), [
                "int": 418,
                "string": "dddd",
                "bool": true
            ])
        }
        else {
            XCTFail()
        }
    }
    
    func testSubscript() {
        let test = TestSubscript(int: 500, string: "Internal Server Error")
        if let data = try? test.encoded() as Data,
           let copy = try? data.decoded() as TestSubscript {
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
        if let test = try? data.decoded() as TestTypeConversions {
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
        if let test2 = try? data2.decoded() as TestTypeConversions {
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
    
    func testCustomTypeConverter() {
        register(FloatToBoolDecodingTypeConverter())
        let data = Data(#"""
        {
            "doubleFromBool": true
        }
        """#.utf8)
        if let test = try? data.decoded() as TestCustomTypeConverter {
            XCTAssertEqual(test, TestCustomTypeConverter(doubleFromBool: 1.0))
        }
        else {
            XCTFail()
        }
    }
    
    func testClass() {
        let test = TestClass(int: 502, string: "Bad Gateway")
        if let data = try? test.encoded() as Data,
           let copy = try? data.decoded() as TestClass {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testSubclass() {
        let test = TestSubclass(int: 504, string: "Gateway Timeout", bool: true)
        if let data = try? test.encoded() as Data,
           let copy = try? data.decoded() as TestSubclass {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testExCodable() {
        let array = [
            TestExCodable(int: 100, string: "Continue"),
            TestExCodable(int: 200, string: "OK"),
            TestExCodable(int: 304, string: "Not Modified"),
            TestExCodable(int: 403, string: "Forbidden"),
            TestExCodable(int: 404, string: "Not Found"),
            TestExCodable(int: 418, string: "I'm a teapot"),
            TestExCodable(int: 500, string: "Internal Server Error"),
            TestExCodable(int: 502, string: "Bad Gateway"),
            TestExCodable(int: 504, string: "Gateway Timeout")
        ]
        let dictionary = [
            "100": TestExCodable(int: 100, string: "Continue"),
            "200": TestExCodable(int: 200, string: "OK"),
            "304": TestExCodable(int: 304, string: "Not Modified"),
            "403": TestExCodable(int: 403, string: "Forbidden"),
            "404": TestExCodable(int: 404, string: "Not Found"),
            "418": TestExCodable(int: 418, string: "I'm a teapot"),
            "500": TestExCodable(int: 500, string: "Internal Server Error"),
            "502": TestExCodable(int: 502, string: "Bad Gateway"),
            "504": TestExCodable(int: 504, string: "Gateway Timeout")
        ]
        
        if let json = try? array.encoded() as Data,
           let copies = try? json.decoded() as [TestExCodable],
           let copies2 = try? [TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, array)
            XCTAssertEqual(copies2, array)
        }
        else {
            XCTFail()
        }
        if let json = try? array.encoded() as [Any],
           let copies = try? json.decoded() as [TestExCodable],
           let copies2 = try? [TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, array)
            XCTAssertEqual(copies2, array)
        }
        else {
            XCTFail()
        }
        if let json = try? array.encoded() as String,
           let copies = try? json.decoded() as [TestExCodable],
           let copies2 = try? [TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, array)
            XCTAssertEqual(copies2, array)
        }
        else {
            XCTFail()
        }
        
        if let json = try? dictionary.encoded() as Data,
           let copies = try? json.decoded() as [String: TestExCodable],
           let copies2 = try? [String: TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, dictionary)
            XCTAssertEqual(copies2, dictionary)
        }
        else {
            XCTFail()
        }
        if let json = try? dictionary.encoded() as [String: Any],
           let copies = try? json.decoded() as [String: TestExCodable],
           let copies2 = try? [String: TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, dictionary)
            XCTAssertEqual(copies2, dictionary)
        }
        else {
            XCTFail()
        }
        if let json = try? dictionary.encoded() as String,
           let copies = try? json.decoded() as [String: TestExCodable],
           let copies2 = try? [String: TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, dictionary)
            XCTAssertEqual(copies2, dictionary)
        }
        else {
            XCTFail()
        }
    }
    
    func testElapsed() {
        let start = DispatchTime.now().uptimeNanoseconds
        
        for _ in 0..<1_0000 {
            let test = TestStruct(int: 304, string: "Not Modified")
            if let data = try? test.encoded() as Data,
               let copy = try? TestStruct.decoded(from: data) {
                XCTAssertEqual(copy, test)
            }
            else {
                XCTFail()
            }
            
            let test2 = TestClass(int: 502, string: "Bad Gateway")
            if let data = try? test2.encoded() as Data,
               let copy = try? data.decoded() as TestClass {
                XCTAssertEqual(copy, test2)
            }
            else {
                XCTFail()
            }
            
            let test3 = TestSubclass(int: 504, string: "Gateway Timeout", bool: true)
            if let data = try? test3.encoded() as Data,
               let copy = try? data.decoded() as TestSubclass {
                XCTAssertEqual(copy, test3)
            }
            else {
                XCTFail()
            }
        }
        
        let elapsed = DispatchTime.now().uptimeNanoseconds - start
        // let seconds = elapsed / 1_000_000_000
        let milliseconds = elapsed / 1_000_000
        print("elapsed: \(milliseconds) ms")
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
        ("testCustomTypeConverter", testCustomTypeConverter),
        ("testClass",           testClass),
        ("testSubclass",        testSubclass),
        ("testExCodable",       testExCodable),
        ("testElapsed",         testElapsed)
    ]
}
