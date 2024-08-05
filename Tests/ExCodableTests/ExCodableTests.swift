//
//  ExCodableTests.swift
//  ExCodable
//
//  Created by Míng on 2021-02-10.
//  Copyright (c) 2023 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
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
        case int
        case nested, string, s
    }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: Keys.self) {
            if let int = try? container.decodeIfPresent(Int.self, forKey: Keys.int) {
                self.int = int
            }
            if let nestedContainer = try? container.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
               let nestedNestedContainer = try? nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested),
               let string = try? nestedNestedContainer.decodeIfPresent(String.self, forKey: Keys.string) {
                self.string = string
            }
            else if let string = (try? container.decodeIfPresent(String.self, forKey: Keys.string))
                        ?? (try? container.decodeIfPresent(String.self, forKey: Keys.s)) {
                self.string = string
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try? container.encodeIfPresent(int, forKey: Keys.int)
        var nestedContainer = container.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested)
        var nestedNestedContainer = nestedContainer.nestedContainer(keyedBy: Keys.self, forKey: Keys.nested)
        try? nestedNestedContainer.encodeIfPresent(string, forKey: Keys.string)
    }
}

// MARK: DEPRECATED

struct TestExCodable_0_x: Equatable {
    private(set) var int: Int = 0
    private(set) var string: String?
}

@available(*, deprecated)
extension TestExCodable_0_x: ExCodableDEPRECATED {
    static let keyMapping: [KeyMap<Self>] = [
        KeyMap(\.int, to: "int"),
        KeyMap(\.string, to: "string")
    ]
    init(from decoder: Decoder) throws {
        try decode(from: decoder, with: Self.keyMapping)
    }
}

// MARK: struct

struct TestStruct: ExAutoCodable, Equatable {
    @ExCodable("int") private(set)
    var int: Int = 0
    @ExCodable("string") private(set)
    var string: String? = nil
    var bool: Bool!
}

// MARK: struct with enum

enum TestEnum: Int, Codable {
    case zero = 0, one = 1
}

struct TestStructWithEnum: ExAutoCodable, Equatable {
    @ExCodable("enum") private(set)
    var `enum` = TestEnum.zero
}

// MARK: alternative-keys

struct TestAlternativeKeys: ExAutoCodable, Equatable {
    @ExCodable("int", "i") private(set)
    var int: Int = 0
    @ExCodable("string", "str", "s") private(set)
    var string: String! = nil
}

// MARK: nested-keys

struct TestNestedKeys: ExAutoCodable, Equatable {
    @ExCodable private(set)
    var int: Int = 0
    @ExCodable("nested.nested.string") private(set)
    var string: String! = nil
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

struct TestCustomEncodeDecode: ExAutoCodable, Equatable {
    
    @ExCodable("int", encode: { encoder, value in
        encoder["int"] = value <= 0 ? 0 : value
    }, decode: { decoder in
        if let int: Int = decoder["int"], int > 0 {
            return int
        }
        return 0
    }) private(set)
    var int: Int = 0
    
    @ExCodable(encode: { encoder, value in
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
    }) private(set)
    var string: String? = nil
    
    @ExCodable(encode: { encoder, value in encoder["bool"] = value },
               decode: { decoder in return decoder["bool"/*, converter: Self.self*/] }) private(set)
    var bool: Bool = false
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

// MARK: type-conversions

struct TestTypeConversion: ExAutoCodable, Equatable {
    @ExCodable("intFromString") private(set)
    var intFromString: Int? = nil
    @ExCodable("stringFromInt") private(set)
    var stringFromInt: String??? = nil
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

struct TestCustomTypeConverter: ExAutoCodable, Equatable {
    @ExCodable("doubleFromBool") private(set)
    var doubleFromBool: Double? = nil
    @ExCodable("boolFromDouble") private(set)
    var boolFromDouble: Bool? = nil
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

class TestClass: ExAutoCodable, Equatable {
    @ExCodable private(set)
    var int: Int = 0
    @ExCodable private(set)
    var string: String? = nil
    
    required init() {}
    init(int: Int, string: String?) {
        (self.int, self.string) = (int, string)
    }
    
    static func == (lhs: TestClass, rhs: TestClass) -> Bool {
        return lhs.int == rhs.int && lhs.string == rhs.string
    }
}

// MARK: subclass

class TestSubclass: TestClass {
    
    @ExCodable private(set)
    var bool: Bool = false
    
    required init() { super.init() }
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

// MARK: nonnull and `throws`

struct TestNonnull: ExAutoCodable, Equatable {
    @ExCodable("int", nonnull: true) private(set)
    var nonnullInt: Int! = 0
}

struct TestNestedNonnull: ExAutoCodable, Equatable {
    @ExCodable("nested.int", "int", nonnull: true) private(set)
    var nonnullInt: Int! = 0
}

struct TestThrows: ExAutoCodable, Equatable {
    @ExCodable("string", "nested.string", throws: true) private(set)
    var throwsString: String! = ""
}

struct TestNestedThrows: ExAutoCodable, Equatable {
    @ExCodable("nested.string", "string", throws: true) private(set)
    var throwsString: String! = ""
}

struct TestNonnullWithThrows: ExAutoCodable, Equatable {
    @ExCodable("throws", nonnull: true) private(set)
    var testThrows: TestThrows! = nil
}

// MARK: ExCodable

struct TestExCodable: ExAutoCodable, Equatable {
    @ExCodable("int") private(set)
    var int: Int = 0
    @ExCodable("string") private(set)
    var string: String? = nil
}

// MARK: - Tests

final class ExCodableTests: XCTestCase {
    
    func testAutoCodable() {
        let test = TestAutoCodable(int: 100, string: "Continue")
        if let data = try? test.encoded() as Data,
           let copy = try? TestAutoCodable.decoded(from: data),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(copy, test)
            XCTAssertEqual(NSDictionary(dictionary: json), ["i": 100, "s": "Continue"])
        }
        else {
            XCTFail()
        }
    }
    
    func testManualCodable() {
        let json = Data(#"{"int":200,"nested":{"nested":{"string":"OK"}}}"#.utf8)
        // decoded with type-inference
        if let test = try? json.decoded() as TestManualCodable,
           let data = try? test.encoded() as Data,
           let copy = try? data.decoded() as TestManualCodable {
            XCTAssertEqual(copy, test)
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            XCTAssertEqual(NSDictionary(dictionary: json), ["int":200,"nested":["nested":["string":"OK"]]])
        }
        else {
            XCTFail()
        }
    }
    
    @available(*, deprecated)
    func testExCodable_0_x() {
        let json = Data(#"{"int":200,"string":"OK"}"#.utf8)
        if let test = try? TestExCodable_0_x.decoded(from: json),
           let data = try? test.encoded() as Data,
           let copy = try? TestExCodable_0_x.decoded(from: data) {
            XCTAssertEqual(copy, test)
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            XCTAssertEqual(NSDictionary(dictionary: json), ["int":200,"string":"OK"])
        }
        else {
            XCTFail()
        }
    }
    
    func testStruct() {
        let test = TestStruct(int: 304, string: "Not Modified"),
            test2 = TestStruct(int: 304, string: "Not Modified", bool: nil)
        if let dict = try? test.encoded() as [String: Any],
           let copy = try? TestStruct.decoded(from: dict),
           let copy2 = try? TestStruct.decoded(from: dict) {
            XCTAssertEqual(copy, test)
            XCTAssertEqual(copy2, test2)
            
            let string = "string: \(test)"
            print(string)
            print(test)
            debugPrint(test)
        }
        else {
            XCTFail()
        }
    }
    
    func testStructWithEnum() {
        let test = TestStructWithEnum(enum: .one)
        if let data = try? test.encoded() as Data,
           let copy1 = try? TestStructWithEnum.decoded(from: data),
           let copy2 = try? TestStructWithEnum.decoded(from: data) {
            XCTAssertEqual(copy1, test)
            XCTAssertEqual(copy2, test)
            
            let string = String(data: data, encoding: .utf8)
            print("TestStructWithEnum: \(string ?? "<nil>")")
        }
        else {
            XCTFail()
        }
    }
    
    func testStructWithEnumFromJSON() {
        let json = Data(#"{"enum":1}"#.utf8)
        if let test = try? TestStructWithEnum.decoded(from: json),
           let data = try? test.encoded() as Data,
           let copy = try? TestStructWithEnum.decoded(from: data) {
            XCTAssertEqual(test, TestStructWithEnum(enum: .one))
            XCTAssertEqual(copy, test)
            let localJSON = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            XCTAssertEqual(NSDictionary(dictionary: localJSON), [
                "enum": 1
            ])
        }
        else {
            XCTFail()
        }
    }
    
    func testStructWithEnumFromJSONWithString() {
        let json = Data(#"{"enum":"1"}"#.utf8)
        if let test = try? TestStructWithEnum.decoded(from: json),
           let data = try? test.encoded() as Data,
           let copy = try? TestStructWithEnum.decoded(from: data) {
            XCTAssertEqual(test, TestStructWithEnum(enum: .one))
            XCTAssertEqual(copy, test)
            let localJSON = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            XCTAssertEqual(NSDictionary(dictionary: localJSON), [
                "enum": 1
            ])
        }
        else {
            XCTFail()
        }
    }
    
    func testAlternativeKeys() {
        let json = Data(#"{"i":403,"s":"Forbidden"}"#.utf8)
        if let test = try? TestAlternativeKeys.decoded(from: json),
           let data = try? test.encoded() as Data,
           let copy = try? TestAlternativeKeys.decoded(from: data) {
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
           let copy = try? TestNestedKeys.decoded(from: data) {
            XCTAssertEqual(copy, test)
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            debugPrint(json)
            XCTAssertEqual(NSDictionary(dictionary: json), [
                "int": 404,
                "nested": [
                    "nested": [
                        "string": "Not Found"
                    ]
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
           let copy = try? TestCustomEncodeDecode.decoded(from: data) {
            XCTAssertEqual(copy, test)
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            debugPrint(json)
            XCTAssertEqual(NSDictionary(dictionary: json), [
                "int": 418,
                "nested": [
                    "nested": [
                        "string": "<placeholder>"
                    ]
                ],
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
           let copy = try? TestSubscript.decoded(from: data) {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testTypeConversion() {
        
        let data = Data(#"""
        {
            "intFromString": "123",
            "stringFromInt": 456
        }
        """#.utf8)
        
        if let test = try? TestTypeConversion.decoded(from: data) {
            XCTAssertEqual(test, TestTypeConversion(intFromString: 123, stringFromInt:  "456"))
        }
        else {
            XCTFail()
        }
        
        let data2 = Data(#"""
        {
            "stringFromInt64": 123
        }
        """#.utf8)
        if let test2 = try? TestTypeConversions.decoded(from: data2) {
            XCTAssertEqual(test2, TestTypeConversions(boolFromInt: nil,
                                                      boolFromString: nil,
                                                      intFromBool: nil,
                                                      intFromDouble: nil,
                                                      intFromString: nil,
                                                      uIntFromBool: nil,
                                                      uIntFromString: nil,
                                                      doubleFromInt64: nil,
                                                      doubleFromString: nil,
                                                      floatFromInt64: nil,
                                                      floatFromString: nil,
                                                      stringFromBool: nil,
                                                      stringFromInt64: "123",
                                                      stringFromDouble: nil))
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
        if let test = try? TestTypeConversions.decoded(from: data) {
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
        if let test2 = try? TestTypeConversions.decoded(from: data2) {
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
        let data = Data(#"""
        {
            "doubleFromBool": true,
            "boolFromDouble": 1.2
        }
        """#.utf8)
        if let test = try? TestCustomTypeConverter.decoded(from: data) {
            XCTAssertEqual(test, TestCustomTypeConverter(doubleFromBool: 1.0, boolFromDouble: true))
        }
        else {
            XCTFail()
        }
    }
    
    func testClass() {
        let test = TestClass(int: 502, string: "Bad Gateway")
        if let data = try? test.encoded() as Data,
           let copy = try? TestClass.decoded(from: data) {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testSubclass() {
        let test = TestSubclass(int: 504, string: "Gateway Timeout", bool: true)
        if let data = try? test.encoded() as Data,
           let copy = try? TestSubclass.decoded(from: data) {
            XCTAssertEqual(copy, test)
        }
        else {
            XCTFail()
        }
    }
    
    func testNonnullAndThrows() {
        
        let noIntData = Data(#"""
        {
            "noInt": true
        }
        """#.utf8)
        XCTAssertThrowsError(try TestNonnull.decoded(from: noIntData)) { error in
            XCTAssertNotNil(error)
            print("TestNonnull error: \(error)")
        }
        XCTAssertThrowsError(try TestNestedNonnull.decoded(from: noIntData)) { error in
            XCTAssertNotNil(error)
            print("TestNestedNonnull error: \(error)")
        }
        
        let nullData = Data(#"""
        {
            "int": null,
            "nested": {
                "int": null
            }
        }
        """#.utf8)
        XCTAssertThrowsError(try TestNonnull.decoded(from: nullData)) { error in
            XCTAssertNotNil(error)
            print("TestNonnull error: \(error)")
        }
        XCTAssertThrowsError(try TestNestedNonnull.decoded(from: nullData)) { error in
            XCTAssertNotNil(error)
            print("TestNestedNonnull error: \(error)")
        }
        
        let nonnullData = Data(#"""
        {
            "int": 1,
            "nested": {
                "int": 1
            }
        }
        """#.utf8)
        XCTAssertEqual(try TestNonnull.decoded(from: nonnullData), TestNonnull(nonnullInt: 1))
        XCTAssertEqual(try TestNestedNonnull.decoded(from: nonnullData), TestNestedNonnull(nonnullInt: 1))
        
        let throwsData = Data(#"""
        {
            "string": [],
            "nested": {
                "string": []
            }
        }
        """#.utf8)
        XCTAssertThrowsError(try TestThrows.decoded(from: throwsData)) { error in
            XCTAssertNotNil(error)
            print("TestThrows error: \(error)")
        }
        XCTAssertThrowsError(try TestNestedThrows.decoded(from: throwsData)) { error in
            XCTAssertNotNil(error)
            print("TestNestedThrows error: \(error)")
        }
        
        let noThrowsData = Data(#"""
        {
            "string": 123
        }
        """#.utf8)
        XCTAssertEqual(try TestThrows.decoded(from: noThrowsData), TestThrows(throwsString: "123"))
        XCTAssertEqual(try TestNestedThrows.decoded(from: noThrowsData), TestNestedThrows(throwsString: "123"))
        
        let nonnullWithThrowsData = Data(#"""
        {
            "throws": {
                "string": []
            }
        }
        """#.utf8)
        XCTAssertThrowsError(try TestNonnullWithThrows.decoded(from: nonnullWithThrowsData)) { error in
            XCTAssertNotNil(error)
            print("TestNonnullWithThrows error: \(error)")
        }
        
        XCTAssertThrowsError(try TestNonnull(nonnullInt: nil).encoded() as Data) { error in
            XCTAssertNotNil(error)
            print("TestNonnull error: \(error)")
        }
        XCTAssertThrowsError(try TestNestedNonnull(nonnullInt: nil).encoded() as Data) { error in
            XCTAssertNotNil(error)
            print("TestNestedNonnull error: \(error)")
        }
        
        XCTAssertThrowsError(try TestThrows(throwsString: nil).encoded() as Data) { error in
            XCTAssertNotNil(error)
            print("TestThrows error: \(error)")
        }
        XCTAssertThrowsError(try TestNestedThrows(throwsString: nil).encoded() as Data) { error in
            XCTAssertNotNil(error)
            print("TestNestedThrows error: \(error)")
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
           let copies = try? [TestExCodable].decoded(from: json),
           let copies2 = try? [TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, array)
            XCTAssertEqual(copies2, array)
        }
        else {
            XCTFail()
        }
        if let json = try? array.encoded() as [Any],
           let copies = try? [TestExCodable].decoded(from: json),
           let copies2 = try? [TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, array)
            XCTAssertEqual(copies2, array)
        }
        else {
            XCTFail()
        }
        if let json = try? array.encoded() as String,
           let copies = try? [TestExCodable].decoded(from: json),
           let copies2 = try? [TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, array)
            XCTAssertEqual(copies2, array)
        }
        else {
            XCTFail()
        }
        
        if let json = try? dictionary.encoded() as Data,
           let copies = try? [String: TestExCodable].decoded(from: json),
           let copies2 = try? [String: TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, dictionary)
            XCTAssertEqual(copies2, dictionary)
        }
        else {
            XCTFail()
        }
        if let json = try? dictionary.encoded() as [String: Any],
           let copies = try? [String: TestExCodable].decoded(from: json),
           let copies2 = try? [String: TestExCodable].decoded(from: json) {
            XCTAssertEqual(copies, dictionary)
            XCTAssertEqual(copies2, dictionary)
        }
        else {
            XCTFail()
        }
        if let json = try? dictionary.encoded() as String,
           let copies = try? [String: TestExCodable].decoded(from: json),
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
               let copy = try? TestClass.decoded(from: data) {
                XCTAssertEqual(copy, test2)
            }
            else {
                XCTFail()
            }
            
            let test3 = TestSubclass(int: 504, string: "Gateway Timeout", bool: true)
            if let data = try? test3.encoded() as Data,
               let copy = try? TestSubclass.decoded(from: data) {
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
        // TODO: compare to builtin and 0.x
    }
}
