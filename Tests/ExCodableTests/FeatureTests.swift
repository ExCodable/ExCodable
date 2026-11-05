//
//  FeatureTests.swift
//  ExCodable
//
//  Created by Míng on 2021-02-10.
//  Copyright (c) 2021 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import XCTest

// @testable
import ExCodable

final class FeatureTests: XCTestCase {
    
    func testAnything() {
        
        func test(_ string: String) {
            print("parsing: \(string)")
            
            if let match = string.wholeMatch(of: /([+-]?[0-9]+)\.?[0-9]*/) {
                print("    match if: \(Int64(match.1) ?? -1)")
            }
            else {
                print("    match else: -1")
            }
            
            if let start = string.firstIndex(of: ".") {
                print("    prefix if: \(Int64(string.prefix(upTo: start)) ?? -1)")
            }
            else {
                print("    prefix else: \(Int64(string) ?? -1)")
            }
            
            print("    prefix 2: \(Int64(string.prefix(upTo: string.firstIndex(of: ".") ?? string.endIndex)) ?? -1)")
        }
        
        test("1234567890")
        test("1234567890.123")
        test("1234567890.")
        test(".123")
        test("0.123")
        test("+1234567890.123")
        test("-1234567890.123")
        test("a1234567890.123")
        test("1234567890.123b")
        test("a1234567890.123b")
        
        XCTAssert(true)
    }
    
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
    
    func testStructWithObservers() throws {
        TestObserverLog.shared.reset()
        let data = Data(#"{"count":3,"name":"ada"}"#.utf8)
        let test = try TestStructWithObservers.decoded(from: data)
        XCTAssertEqual(test, TestStructWithObservers(count: 3, name: "ada"))
        // `init(from:)` assigns stored properties, and Swift runs no observers during
        // initialization, so decoding must not fire `willSet` / `didSet`.
        XCTAssertEqual(TestObserverLog.shared.events, [])
        
        let encoded = try test.encoded() as Data
        let copy = try TestStructWithObservers.decoded(from: encoded)
        XCTAssertEqual(copy, test)
        XCTAssertEqual(TestObserverLog.shared.events, [])
    }
    
    func testStructWithObserversFireOnAssignment() {
        var test = TestStructWithObservers(count: 0, name: nil)
        TestObserverLog.shared.reset()
        
        test.count = 9
        XCTAssertEqual(TestObserverLog.shared.events, ["count.willSet:9", "count.didSet:9"])
        
        TestObserverLog.shared.reset()
        test.name = "ada"
        XCTAssertEqual(TestObserverLog.shared.events, ["name.didSet:Optional(\"ada\")"])
    }
    
    func testFixedLet() throws {
        let made = TestFixedLet(id: 7)
        XCTAssertEqual(made.kind, "user")
        XCTAssertEqual(made.role, "member")
        
        let decoded = try TestFixedLet.decoded(from: Data(#"{"id":7}"#.utf8))
        XCTAssertEqual(decoded, made)
        
        let encoded = try decoded.encoded() as Data
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        XCTAssertEqual(json["id"] as? Int, 7)
        XCTAssertNil(json["kind"])
        XCTAssertNil(json["role"])
    }
    
    func testStructWithOptionals() {
        let test = TestStructWithOptionals(bool: true,
                                           int: 1,
                                           int8: 8,
                                           int16: 16,
                                           int32: 32,
                                           int64: 64,
                                           uInt: 1,
                                           uInt8: 8,
                                           uInt16: 16,
                                           uInt32: 32,
                                           uInt64: 64,
                                           double: 1.123456789,
                                           float: 1.1,
                                           float16: 1.16,
                                           float32: 1.32,
                                           float64: 1.64,
                                           string: "string")
        if let data = try? test.encoded() as Data,
           let copy = try? TestStructWithOptionals.decoded(from: data) {
            XCTAssertEqual(copy, test)
            let string = String(data: data, encoding: .utf8)
            print("TestStructWithOptionals: \(string ?? "<nil>")")
        }
        else {
            XCTFail()
        }
    }
    
    func testStructWithEnum() {
        let test = TestStructWithEnum(enum: .one)
        if let data = try? test.encoded() as Data,
           let copy = try? TestStructWithEnum.decoded(from: data) {
            XCTAssertEqual(copy, test)
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
    
    func testStructWithOptionalEnumFromJSON() {
        let json = Data(#"{"enum":1}"#.utf8)
        if let test = try? TestStructWithOptionalEnum.decoded(from: json),
           let data = try? test.encoded() as Data,
           let copy = try? TestStructWithOptionalEnum.decoded(from: data) {
            XCTAssertEqual(test, TestStructWithOptionalEnum(enum: .one))
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
    
    func testStructWithOptionalEnumFromJSONWithString() {
        let json = Data(#"{"enum":"1"}"#.utf8)
        if let test = try? TestStructWithOptionalEnum.decoded(from: json),
           let data = try? test.encoded() as Data,
           let copy = try? TestStructWithOptionalEnum.decoded(from: data) {
            XCTAssertEqual(test, TestStructWithOptionalEnum(enum: .one))
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
    
    func testStructWithOptionalEnumFromNullOrMissingOrUnknown() {
        if let nullJSON = try? TestStructWithOptionalEnum.decoded(from: Data(#"{"enum":null}"#.utf8)),
           let missingJSON = try? TestStructWithOptionalEnum.decoded(from: Data(#"{}"#.utf8)),
           let unknownJSON = try? TestStructWithOptionalEnum.decoded(from: Data(#"{"enum":"9"}"#.utf8)) {
            XCTAssertEqual(nullJSON, TestStructWithOptionalEnum(enum: nil))
            XCTAssertEqual(missingJSON, TestStructWithOptionalEnum(enum: nil))
            XCTAssertEqual(unknownJSON, TestStructWithOptionalEnum(enum: nil))
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
    
    func testNestedSiblingKeys() throws {
        let data = try TestNestedSiblings(name: "Ada", role: "admin").encoded() as Data
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(NSDictionary(dictionary: json), [
            "user": [
                "name": "Ada",
                "role": "admin"
            ]
        ])
    }
    
    func testDotPathPrefixClash() throws {
        let data = try TestDotPathPrefixClash(user: TestDotPathPrefixClashUser(id: 1), name: "Ada").encoded() as Data
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let user = json["user"] as? [String: Any]
        let id = user?["id"] as? Int
        let name = user?["name"] as? String
        XCTAssertEqual(id, 1)
        XCTAssertEqual(name, "Ada")
    }
    
    func testDotPathEmptyKey() throws {
        _ = try TestDotPathEmpty(value: "Ada").encoded() as Data
    }
    
    func testDotPathTrailingDot() throws {
        let data = try TestDotPathTrailing(name: "Ada").encoded() as Data
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["user"] as? String, "Ada")
    }
    
    func testDotPathRepeatedDot() throws {
        let data = try TestDotPathRepeated(name: "Ada").encoded() as Data
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let a = json["a"] as? [String: Any]
        let b = a?["b"] as? String
        XCTAssertEqual(b, "Ada")
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
    
    func testIntegerRange() throws {
        let fractional = try TestIntegerRange.decoded(from: Data(#"{"int8":1.9,"uInt8":1.9,"uInt64":1.9}"#.utf8))
        XCTAssertEqual(fractional.int8, 1)
        XCTAssertEqual(fractional.uInt8, 1)
        XCTAssertEqual(fractional.uInt64, 1)
        
        let negative = try TestIntegerRange.decoded(from: Data(#"{"int8":-1.9,"uInt8":-1.5,"uInt64":-1}"#.utf8))
        XCTAssertEqual(negative.int8, -1)
        XCTAssertNil(negative.uInt8)
        XCTAssertNil(negative.uInt64)
        
        let overflow = try TestIntegerRange.decoded(from: Data(#"{"int8":200,"uInt8":300,"uInt64":1e20}"#.utf8))
        XCTAssertNil(overflow.int8)
        XCTAssertNil(overflow.uInt8)
        XCTAssertNil(overflow.uInt64)
        
        let strings = try TestIntegerRange.decoded(from: Data(#"{"int8":"256","uInt8":"-1","uInt64":"18446744073709551615"}"#.utf8))
        XCTAssertNil(strings.int8)
        XCTAssertNil(strings.uInt8)
        XCTAssertEqual(strings.uInt64, UInt64.max)
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
    
    func testTypeConversionsForOptionals() {
        let data = Data(#"""
        {
            "uInt8":    "8",
            "float":    "1.1",
            "float64":  "1.64",
            "int8":     "8",
            "bool":     "true",
            "int":      "1",
            "double":   "1.123456789",
            "int16":    "16",
            "uInt":     "1",
            "float16":  "1.1601562",
            "uInt32":   "32",
            "int32":    "32",
            "string":   "string",
            "uInt16":   "16",
            "float32":  "1.32",
            "int64":    "64",
            "uInt64":   "64"
        }
        """#.utf8)
        if let test = try? TestStructWithOptionals.decoded(from: data) {
            XCTAssertEqual(test, TestStructWithOptionals(bool:      true,
                                                         int:       1,
                                                         int8:      8,
                                                         int16:     16,
                                                         int32:     32,
                                                         int64:     64,
                                                         uInt:      1,
                                                         uInt8:     8,
                                                         uInt16:    16,
                                                         uInt32:    32,
                                                         uInt64:    64,
                                                         double:    1.123456789,
                                                         float:     1.1,
                                                         float16:   1.16, // Float16: 1.1601562 ~= 1.16
                                                         float32:   1.32,
                                                         float64:   1.64,
                                                         string:    "string"))
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
    
    func testExplicitCodableAndGenerics() throws {
        let explicit = try TestExplicitCodable.decoded(from: Data(#"{"id":7}"#.utf8))
        XCTAssertEqual(explicit, TestExplicitCodable(id: 7))
        let explicitData = try explicit.encoded() as Data
        XCTAssertEqual(try TestExplicitCodable.decoded(from: explicitData), explicit)
        
        let box = try TestGenericBox<String>.decoded(from: Data(#"{"value":"box"}"#.utf8))
        XCTAssertEqual(box.value, "box")
        
        let free = try TestFreeGeneric<Int>.decoded(from: Data(#"{"value":7}"#.utf8))
        XCTAssertEqual(free.value, 7)
        
        let partial = try TestPartialGeneric<Int, String>.decoded(from: Data(#"{"a":1,"b":"two"}"#.utf8))
        XCTAssertEqual(partial.a, 1)
        XCTAssertEqual(partial.b, "two")
        
        let object = try TestGenericClass<Int>.decoded(from: Data(#"{"value":3}"#.utf8))
        XCTAssertEqual(object.value, 3)
        let objectData = try object.encoded() as Data
        XCTAssertEqual(try TestGenericClass<Int>.decoded(from: objectData).value, 3)
    }
    
    func testDefault() throws {
        let values = Data(#"{"int":418,"int2":"invalid-value","string":"I'm a teapot"}"#.utf8)
        let decoded = try TestDefault.decoded(from: values)
        XCTAssertEqual(decoded.int, 418)
        XCTAssertEqual(decoded.int2, 2)
        XCTAssertEqual(decoded.string, "I'm a teapot")
        
        let missing = Data(#"{}"#.utf8)
        let `default` = try TestDefault.decoded(from: missing)
        XCTAssertEqual(`default`.int, 1)
        XCTAssertEqual(`default`.int2, 2)
        XCTAssertEqual(`default`.string, "default")
        
        let nulls = Data(#"{"int":null,"string":null}"#.utf8)
        let nullToDefault = try TestDefault.decoded(from: nulls)
        XCTAssertEqual(nullToDefault.int, 1)
        XCTAssertEqual(nullToDefault.int2, 2)
        XCTAssertEqual(nullToDefault.string, "default")
        
        let data = try decoded.encoded() as Data
        let copy = try TestDefault.decoded(from: data)
        XCTAssertEqual(copy.int, decoded.int)
        XCTAssertEqual(copy.int2, decoded.int2)
        XCTAssertEqual(copy.string, decoded.string)
    }
    
    /// A property initializer doubles as the default value when decode failed for every supported type.
    func testInitialDefaultValueForAllTypes() throws {
        let expected = TestInitialDefaultValue(
            int8: 8, uint: 1, double: 2.5, float16: 2.5, bool: true,
            string: "initial", url: URL(string: "https://initial.example")!,
            uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            array: [1, 2], dictionary: ["a": 1], enum: .one,
            nested: TestNestedValue(x: 9), optional: 5
        )
        
        // Missing keys, JSON null, wrong JSON types and values outside a type's range must all
        // fall back to the initializer instead of throwing.
        let failures: [String] = [
            "{}",
            #"""
            {"int8":null,"uint":null,"double":null,"float16":null,"bool":null,"string":null,
             "url":null,"uuid":null,"array":null,"dictionary":null,"enum":null,
             "nested":null,"optional":null}
            """#,
            // `url` is left out on purpose: `URL` accepts nearly any string, so a "bad" URL
            // does not fail and therefore keeps the decoded value instead of the initial one.
            #"""
            {"int8":999,"uint":-1,"double":"1e400","float16":70000,"bool":"maybe","string":[],
             "uuid":"not-a-uuid","array":"not-an-array","dictionary":1,
             "enum":99,"nested":{"x":"bad"},"optional":"bad"}
            """#
        ]
        for json in failures {
            let decoded = try TestInitialDefaultValue.decoded(from: Data(json.utf8))
            XCTAssertEqual(decoded, expected, "initial values must survive: \(json)")
        }
    }
    
    /// JSON values that convert cleanly must still override the initializer.
    func testInitialValueOverriddenByConvertibleJSON() throws {
        let json = Data(#"""
        {"int8":"16","uint":true,"double":"1.5","float16":"1.5","bool":"yes","string":1,
         "uuid":"11111111-1111-1111-1111-111111111111","array":[3],
         "dictionary":{"b":2},"enum":1,"nested":{"x":1},"optional":7}
        """#.utf8)
        let decoded = try TestInitialDefaultValue.decoded(from: json)
        XCTAssertEqual(decoded.int8, 16)
        XCTAssertEqual(decoded.uint, 1)
        XCTAssertEqual(decoded.double, 1.5)
        XCTAssertEqual(decoded.float16, 1.5)
        XCTAssertEqual(decoded.bool, true)
        XCTAssertEqual(decoded.string, "1")
        XCTAssertEqual(decoded.uuid, UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        XCTAssertEqual(decoded.array, [3])
        XCTAssertEqual(decoded.dictionary, ["b": 2])
        XCTAssertEqual(decoded.enum, .one)
        XCTAssertEqual(decoded.nested, TestNestedValue(x: 1))
        XCTAssertEqual(decoded.optional, 7)
    }
    
    /// Without an initializer there is nothing to fall back to, so a failure throws.
    func testNoInitialValueThrows() {
        XCTAssertThrowsError(try TestNoInitialValue.decoded(from: Data("{}".utf8)))
        XCTAssertThrowsError(try TestNoInitialValue.decoded(from: Data(#"{"array":["a"]}"#.utf8)))
    }
    
    /// An initial value absorbs a failed decode, even though the property is required.
    func testInitialValueWithRequiredOrStrictType() throws {
        for json in ["{}", #"{"int":null}"#, #"{"int":"bad"}"#] {
            XCTAssertEqual(try TestInitialValueRequired.decoded(from: Data(json.utf8)).int, 2, json)
        }
        XCTAssertEqual(try TestInitialValueRequired.decoded(from: Data(#"{"int":3}"#.utf8)).int, 3)
    }
    
    /// `URL` accepts almost any string, so a malformed URL does not fall back. Documented here
    /// so the exception is intentional rather than a silent surprise.
    func testInitialValueURLKeepsDecodedValue() throws {
        let decoded = try TestInitialDefaultValue.decoded(from: Data(#"{"url":"%%%"}"#.utf8))
        XCTAssertEqual(decoded.url.absoluteString, "%25%25%25")
        XCTAssertNotEqual(decoded.url, URL(string: "https://initial.example")!)
    }
    
    func testOptionsExCodableKeysIsTheDefault() throws {
        // `@ExCodable`, `@ExCodable()` and `@ExCodable(.exCodableKeys)` behave the same:
        // only `@ExCodableKey` properties are coded.
        let json = Data(#"{"key":1,"unmarked":9}"#.utf8)
        let defaulted = try TestExCodableKeysDefault.decoded(from: json)
        let explicit = try TestExCodableKeysExplicit.decoded(from: json)
        XCTAssertEqual(defaulted, TestExCodableKeysDefault(key: 1, unmarked: 0))
        XCTAssertEqual(explicit, TestExCodableKeysExplicit(key: 1, unmarked: 0))
        XCTAssertEqual(try defaulted.encoded() as Data, try explicit.encoded() as Data)
        XCTAssertEqual(NSDictionary(dictionary: try JSONSerialization.jsonObject(with: try defaulted.encoded() as Data) as! [String: Any]),
                       ["key": 1])
    }
    
    func testOptionsAllKeys() throws {
        let decoded = try TestAllKeys.decoded(from: Data(#"{"int":1,"string":"x"}"#.utf8))
        XCTAssertEqual(decoded, TestAllKeys(int: 1, string: "x"))
        let json = try JSONSerialization.jsonObject(with: try decoded.encoded() as Data) as! [String: Any]
        XCTAssertEqual(NSDictionary(dictionary: json), ["int": 1, "string": "x"])
    }
    
    /// `.allKeys` and `ExCodableOptions.allKeys` are the only accepted spellings, and both
    /// resolve to the same behaviour.
    func testOptionsAllKeysQualified() throws {
        let decoded = try TestAllKeysQualified.decoded(from: Data(#"{"int":4}"#.utf8))
        XCTAssertEqual(decoded, TestAllKeysQualified(int: 4))
        let json = try JSONSerialization.jsonObject(with: try decoded.encoded() as Data) as! [String: Any]
        XCTAssertEqual(NSDictionary(dictionary: json), ["int": 4])
    }
    
    func testOptionsAllKeysWithExcept() throws {
        let json = Data(#"{"kept":1,"excluded":"from json","extra":99}"#.utf8)
        let decoded = try TestAllKeysWithExcept.decoded(from: json)
        // Only the property marked `@ExCodableExcept` is held back; its siblings are coded, so
        // JSON overrides `extra`'s initializer like any other key.
        XCTAssertEqual(decoded, TestAllKeysWithExcept(kept: 1, excluded: "initial", extra: 99))
        let encoded = try JSONSerialization.jsonObject(with: try decoded.encoded() as Data) as! [String: Any]
        XCTAssertEqual(NSDictionary(dictionary: encoded), ["kept": 1, "extra": 99])
    }
    
    /// A property with no `@ExCodableKey` under `.allKeys` behaves exactly like one that has it.
    func testOptionsAllKeysTreatsUnmarkedLikeExplicitKey() throws {
        let json = Data(#"{"kept":2,"excluded":"ignored","extra":5}"#.utf8)
        let implicit = try TestAllKeysWithExcept.decoded(from: json)
        let explicit = try TestAllKeysWithExceptExplicit.decoded(from: json)
        XCTAssertEqual(implicit.kept, explicit.kept)
        XCTAssertEqual(implicit.excluded, explicit.excluded)
        XCTAssertEqual(implicit.extra, explicit.extra)
        // Compare parsed JSON: `JSONEncoder` does not guarantee key order across distinct types.
        let implicitJSON = try JSONSerialization.jsonObject(with: try implicit.encoded() as Data) as! [String: Any]
        let explicitJSON = try JSONSerialization.jsonObject(with: try explicit.encoded() as Data) as! [String: Any]
        XCTAssertEqual(NSDictionary(dictionary: implicitJSON), NSDictionary(dictionary: explicitJSON))
        
        // Missing key: both keep the initial value, so the default value is the same either way.
        let partial = Data(#"{"kept":2}"#.utf8)
        XCTAssertEqual(try TestAllKeysWithExcept.decoded(from: partial).extra, 7)
        XCTAssertEqual(try TestAllKeysWithExceptExplicit.decoded(from: partial).extra, 7)
    }
    
    func testOptionsAllKeysWithExplicitKey() throws {
        // An explicit `@ExCodableKey` keeps its own keys and parameters.
        let decoded = try TestAllKeysWithExplicitKey.decoded(from: Data(#"{"unmarked":1,"renamed":"r"}"#.utf8))
        XCTAssertEqual(decoded, TestAllKeysWithExplicitKey(unmarked: 1, renamedFrom: "r"))
        let json = try JSONSerialization.jsonObject(with: try decoded.encoded() as Data) as! [String: Any]
        XCTAssertEqual(NSDictionary(dictionary: json), ["unmarked": 1, "renamed": "r"])
        XCTAssertThrowsError(try TestAllKeysWithExplicitKey.decoded(from: Data(#"{"unmarked":1}"#.utf8)))
    }
    
    func testOptionsAllKeysKeepsFixedLet() throws {
        // A `let` with an initial value stays a fixed field, exactly as in `.exCodableKeys`.
        let decoded = try TestAllKeysWithFixedLet.decoded(from: Data(#"{"value":2,"kind":"hacked"}"#.utf8))
        XCTAssertEqual(decoded.kind, "user")
        XCTAssertEqual(decoded.value, 2)
        XCTAssertEqual(TestAllKeysWithFixedLet(value: 3).kind, "user")
        let json = try JSONSerialization.jsonObject(with: try decoded.encoded() as Data) as! [String: Any]
        XCTAssertEqual(NSDictionary(dictionary: json), ["value": 2])
    }
    
    func testOptionsAllKeysForClass() throws {
        let decoded = try TestAllKeysClass.decoded(from: Data(#"{"int":5,"excluded":"ignored"}"#.utf8))
        XCTAssertEqual(decoded.int, 5)
        XCTAssertEqual(decoded.excluded, "initial")
        let json = try JSONSerialization.jsonObject(with: try decoded.encoded() as Data) as! [String: Any]
        XCTAssertEqual(NSDictionary(dictionary: json), ["int": 5])
    }
    
    /// `@ExCodableExcept` under `.exCodableKeys` is inert: the property stays out of coding either way,
    /// so the only difference from omitting the attribute is the compile-time warning.
    func testExceptInExCodableKeysIsInert() throws {
        let decoded = try TestExceptInExCodableKeys.decoded(from: Data(#"{"key":1,"excluded":9}"#.utf8))
        XCTAssertEqual(decoded, TestExceptInExCodableKeys(key: 1, excluded: 3))
        let json = try JSONSerialization.jsonObject(with: try decoded.encoded() as Data) as! [String: Any]
        XCTAssertEqual(NSDictionary(dictionary: json), ["key": 1])
    }
    
    /// Keys are emitted as Swift string literals, so quotes, backslashes and control characters
    /// must survive the round trip instead of producing broken generated code.
    func testEscapedKeys() throws {
        let json = Data(#"{"has\"quote":1,"has\\backslash":2,"has\ttab":3,"has\nnewline":4}"#.utf8)
        let decoded = try TestEscapedKeys.decoded(from: json)
        XCTAssertEqual(decoded, TestEscapedKeys(quote: 1, backslash: 2, tab: 3, newline: 4))
        XCTAssertEqual(try TestEscapedKeys.decoded(from: try decoded.encoded() as Data), decoded)
    }
    
    func testDecodingError() {
        let noKeyData = Data(#"{}"#.utf8)
        let typeMismatchData = Data(#"{"v":"abc"}"#.utf8)
        
        XCTAssertThrowsError(try TestMatrixRequiredPermissive.decoded(from: noKeyData)) { error in
            if case DecodingError.keyNotFound(let codingKey, let context) = error {
                print("DecodingError.keyNotFound(\(codingKey), \(context))")
            }
            else {
                print("NOT DecodingError.keyNotFound: \(error)")
                XCTFail()
            }
        }
        
        XCTAssertThrowsError(try TestMatrixRequiredStrict.decoded(from: noKeyData)) { error in
            if case DecodingError.keyNotFound(let codingKey, let context) = error {
                print("DecodingError.keyNotFound(\(codingKey), \(context))")
            }
            else {
                print("NOT DecodingError.keyNotFound: \(error)")
                XCTFail()
            }
        }
        
        XCTAssertThrowsError(try TestMatrixRequiredPermissive.decoded(from: typeMismatchData)) { error in
            if case DecodingError.typeMismatch(let codingKey, let context) = error {
                print("DecodingError.typeMismatch(\(codingKey), \(context))")
            }
            else {
                print("NOT DecodingError.typeMismatch: \(error)")
                XCTFail()
            }
        }
    }
    
    /// Pins the error reported for every combination of optionality and `strictType`.
    ///
    /// - Required (non-optional) is always strict about presence: a missing key or `null` fails.
    /// - Optional absorbs both, unless `strictType` asks for a type error to surface.
    /// - A value that converts (`"1"` for `Int`) is never an error, strict or not.
    func testErrorMatrix() throws {
        typealias Case = (json: String, required: String?, optional: String?)
        // `nil` means "decodes successfully". An optional property has `nil` to fall back on, so
        // `strictType` never makes it report a missing value — only a type error.
        let cases: [Case] = [
            ("{}",                        "keyNotFound",   nil),
            (#"{"v":null}"#,              "valueNotFound", nil),
            (#"{"v":"abc"}"#,             "typeMismatch",  "typeMismatch"),
            (#"{"v":"1"}"#,               nil,             nil),
            (#"{"v":1}"#,                 nil,             nil),
        ]
        
        func thrown<T: Decodable>(_ type: T.Type, _ json: String) -> String? {
            do {
                let // ???: `let` to forbid warning: `'catch' block is unreachable because no errors are thrown in 'do' block`
                _ = try T.decoded(from: Data(json.utf8))
                return nil
            }
            catch let error as DecodingError {
                return switch error {
                    case .keyNotFound: "keyNotFound"
                    case .valueNotFound: "valueNotFound"
                    case .typeMismatch: "typeMismatch"
                    case .dataCorrupted: "dataCorrupted"
                    @unknown default: "unknown"
                }
            }
            catch {
                return String(describing: error)
            }
        }
        
        for (json, requiredError, optionalError) in cases {
            XCTAssertEqual(thrown(TestMatrixRequiredPermissive.self, json), requiredError,
                           "required/permissive \(json)")
            XCTAssertEqual(thrown(TestMatrixRequiredStrict.self, json), requiredError,
                           "required/strict \(json)")
            // An optional property only reports the type mismatch `strictType` asks for.
            XCTAssertEqual(thrown(TestMatrixOptionalPermissive.self, json), nil,
                           "optional/permissive \(json)")
            XCTAssertEqual(thrown(TestMatrixOptionalStrict.self, json), optionalError,
                           "optional/strict \(json)")
        }
    }
    
    /// The error a decode throws, as a name. `nil` means it decoded.
    private func thrown<T: Decodable>(_ type: T.Type, _ json: String) -> String? {
        do {
            let // ???: `let` to forbid warning: `'catch' block is unreachable because no errors are thrown in 'do' block`
            _ = try T.decoded(from: Data(json.utf8))
            return nil
        }
        catch let error as DecodingError {
            return switch error {
                case .keyNotFound: "keyNotFound"
                case .valueNotFound: "valueNotFound"
                case .typeMismatch: "typeMismatch"
                case .dataCorrupted: "dataCorrupted"
                @unknown default: "unknown"
            }
        }
        catch {
            return String(describing: error)
        }
    }
    
    /// A value of the right JSON type that is not a case of the enum, such as `9` for `TestEnum` or `"z"` for `TestStringEnum`.
    ///
    /// That is a value error, not a type error, so `strictType` does not report it. An optional property becomes `nil`, a
    /// required property throws `valueNotFound`, and `default` replaces it. A wrong JSON type is a `typeMismatch`.
    func testInvalidEnumValue() throws {
        // Int enum: `9` is an Int that is not a case.
        XCTAssertEqual(thrown(TestEnumRequired.self,         #"{"v":9}"#), "valueNotFound", "required")
        XCTAssertEqual(thrown(TestEnumRequiredStrict.self,   #"{"v":9}"#), "valueNotFound", "required/strict")
        XCTAssertNil(  thrown(TestEnumOptional.self,         #"{"v":9}"#),                  "optional")
        XCTAssertNil(  thrown(TestEnumOptionalStrict.self,   #"{"v":9}"#),                  "optional/strict")
        XCTAssertNil(  thrown(TestEnumDefault.self,          #"{"v":9}"#),                  "default")
        
        // String enum: `"z"` is a String that is not a case.
        XCTAssertEqual(thrown(TestStringEnumRequired.self,       #"{"v":"z"}"#), "valueNotFound", "required")
        XCTAssertEqual(thrown(TestStringEnumRequiredStrict.self, #"{"v":"z"}"#), "valueNotFound", "required/strict")
        XCTAssertNil(  thrown(TestStringEnumOptional.self,       #"{"v":"z"}"#),                  "optional")
        XCTAssertNil(  thrown(TestStringEnumOptionalStrict.self, #"{"v":"z"}"#),                  "optional/strict")
        XCTAssertNil(  thrown(TestStringEnumDefault.self,        #"{"v":"z"}"#),                  "default")
        
        // A wrong JSON type is a `typeMismatch`, and `strictType` is what makes an optional property report it.
        XCTAssertEqual(thrown(TestEnumRequired.self,             #"{"v":"x"}"#), "typeMismatch", "required")
        XCTAssertNil(  thrown(TestEnumOptional.self,             #"{"v":"x"}"#),                 "optional")
        XCTAssertEqual(thrown(TestEnumOptionalStrict.self,       #"{"v":"x"}"#), "typeMismatch", "optional/strict")
        XCTAssertEqual(thrown(TestStringEnumRequired.self,       #"{"v":[1]}"#), "typeMismatch", "required")
        XCTAssertNil(  thrown(TestStringEnumOptional.self,       #"{"v":[1]}"#),                 "optional")
        XCTAssertEqual(thrown(TestStringEnumOptionalStrict.self, #"{"v":[1]}"#), "typeMismatch", "optional/strict")
        
        // The builtin conversion turns `true` and `1` into the strings "true" and "1". They are strings, just not cases, so it is a value error.
        XCTAssertEqual(thrown(TestStringEnumRequired.self,       #"{"v":true}"#), "valueNotFound", "required")
        XCTAssertNil(  thrown(TestStringEnumOptionalStrict.self, #"{"v":true}"#),                  "optional/strict")
        XCTAssertEqual(thrown(TestStringEnumRequired.self,       #"{"v":1}"#),    "valueNotFound", "required")
        
        // A valid value still decodes, including the string form of an Int case.
        XCTAssertNil(thrown(TestEnumRequired.self,       #"{"v":1}"#))
        XCTAssertNil(thrown(TestEnumRequired.self,       #"{"v":"1"}"#))
        XCTAssertNil(thrown(TestEnumOptionalStrict.self, #"{"v":1}"#))
        XCTAssertNil(thrown(TestStringEnumRequired.self, #"{"v":"two"}"#))
        
        // `default` is only used when decoding fails, so a valid value wins.
        XCTAssertEqual(try TestEnumDefault.decoded(from: Data(#"{"v":0}"#.utf8)).v, .zero)
        XCTAssertEqual(try TestEnumDefault.decoded(from: Data(#"{"v":9}"#.utf8)).v, .one)
        XCTAssertEqual(try TestStringEnumDefault.decoded(from: Data(#"{"v":"two"}"#.utf8)).v, .two)
        XCTAssertEqual(try TestStringEnumDefault.decoded(from: Data(#"{"v":"z"}"#.utf8)).v, .one)
    }
    
    /// A nested key `a.b` is first tried as one key named "a.b", which is never there, and then as the path `a` then `b`.
    /// The error of the path is the one that describes the data, so it must win over that `keyNotFound`.
    func testNestedKeyReportsTheValueError() throws {
        // The path exists, the value is wrong.
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":{"b":9}}"#),   "valueNotFound", "invalid enum value")
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":{"b":"x"}}"#), "typeMismatch",  "wrong JSON type")
        XCTAssertEqual(thrown(TestNestedStringRequired.self, #"{"a":{"b":[1]}}"#), "typeMismatch",  "wrong JSON type")
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":{"b":null}}"#), "valueNotFound", "null")
        XCTAssertNil(  thrown(TestNestedEnumOptionalStrict.self, #"{"a":{"b":9}}"#),                "optional/strict invalid enum value")
        XCTAssertEqual(thrown(TestNestedEnumOptionalStrict.self, #"{"a":{"b":"x"}}"#), "typeMismatch", "optional/strict wrong JSON type")
        
        // The path is really missing, so `keyNotFound` is the right answer.
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":{}}"#), "keyNotFound", "b missing")
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{}"#),       "keyNotFound", "a missing")
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":1}"#),  "keyNotFound", "a is not an object")
        
        // It still decodes.
        XCTAssertNil(thrown(TestNestedEnumRequired.self, #"{"a":{"b":1}}"#))
        
        // Alternative keys: the second key has the value but it is wrong, and the first key is simply absent.
        XCTAssertEqual(thrown(TestNestedAlternativeKeys.self, #"{"a":{"b":9}}"#), "valueNotFound", "alternative keys")
        XCTAssertNil(  thrown(TestNestedAlternativeKeys.self, #"{"a":{"b":1}}"#))
    }
    
    func testRequiredAndStrictType() throws {
        
        let noIntData = Data(#"""
        {
            "noInt": true
        }
        """#.utf8)
        XCTAssertThrowsError(try TestRequired.decoded(from: noIntData)) { error in
            guard case DecodingError.keyNotFound = error else { return XCTFail("\(error)") }
            print("TestRequired error: \(error)")
        }
        XCTAssertThrowsError(try TestNestedRequired.decoded(from: noIntData)) { error in
            XCTAssertNotNil(error)
            print("TestNestedRequired error: \(error)")
        }
        
        let nullData = Data(#"""
        {
            "int": null,
            "nested": {
                "int": null
            }
        }
        """#.utf8)
        XCTAssertThrowsError(try TestRequired.decoded(from: nullData)) { error in
            guard case DecodingError.valueNotFound = error else { return XCTFail("\(error)") }
            print("TestRequired error: \(error)")
        }
        XCTAssertThrowsError(try TestNestedRequired.decoded(from: nullData)) { error in
            XCTAssertNotNil(error)
            print("TestNestedRequired error: \(error)")
        }
        
        let requiredData = Data(#"""
        {
            "int": 1,
            "nested": {
                "int": 1
            }
        }
        """#.utf8)
        XCTAssertEqual(try TestRequired.decoded(from: requiredData), TestRequired(requiredInt: 1))
        XCTAssertEqual(try TestNestedRequired.decoded(from: requiredData), TestNestedRequired(requiredInt: 1))
        
        let throwsData = Data(#"""
        {
            "string": [],
            "nested": {
                "string": []
            }
        }
        """#.utf8)
        XCTAssertThrowsError(try TestStrictType.decoded(from: throwsData)) { error in
            XCTAssertNotNil(error)
            print("TestStrictType error: \(error)")
        }
        XCTAssertThrowsError(try TestNestedStrictType.decoded(from: throwsData)) { error in
            XCTAssertNotNil(error)
            print("TestNestedStrictType error: \(error)")
        }
        
        let permissiveData = Data(#"""
        {
            "string": 123
        }
        """#.utf8)
        XCTAssertEqual(try TestStrictType.decoded(from: permissiveData), TestStrictType(strictTypeString: "123"))
        XCTAssertEqual(try TestNestedStrictType.decoded(from: permissiveData), TestNestedStrictType(strictTypeString: "123"))
        
        let requiredAndStrictTypeData = Data(#"""
        {
            "throws": {
                "string": []
            }
        }
        """#.utf8)
        XCTAssertThrowsError(try TestRequiredAndStrictType.decoded(from: requiredAndStrictTypeData)) { error in
            XCTAssertNotNil(error)
            print("TestRequiredAndStrictType error: \(error)")
        }
        
        XCTAssertThrowsError(try TestRequired(requiredInt: nil).encoded() as Data) { error in
            XCTAssertNotNil(error)
            print("TestRequired error: \(error)")
        }
        XCTAssertThrowsError(try TestNestedRequired(requiredInt: nil).encoded() as Data) { error in
            XCTAssertNotNil(error)
            print("TestNestedRequired error: \(error)")
        }
        
        // `String!` is required, so encoding nil must fail rather than silently drop the key.
        XCTAssertThrowsError(try TestStrictType(strictTypeString: nil).encoded() as Data)
        XCTAssertThrowsError(try TestNestedStrictType(strictTypeString: nil).encoded() as Data)
        
        let partial = try TestStruct(int: 1, string: nil).encoded() as Data
        let partialJSON = try JSONSerialization.jsonObject(with: partial) as! [String: Any]
        XCTAssertEqual(partialJSON["int"] as? Int, 1)
        XCTAssertNil(partialJSON["string"])
        XCTAssertEqual(partialJSON.count, 1)
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
    
    /// `@MainActor` types get an isolated `Codable` conformance from the macro.
    @MainActor
    func testMainActor() throws {
        let value = try TestMainActorStruct.decoded(from: Data(#"{"int":1,"string":"a"}"#.utf8))
        XCTAssertEqual(value, TestMainActorStruct(int: 1, string: "a"))
        let data: Data = try value.encoded()
        XCTAssertEqual(try TestMainActorStruct.decoded(from: data), value)
        
        let subclass = try TestMainActorSubclass.decoded(from: Data(#"{"int":2,"string":"b"}"#.utf8))
        XCTAssertEqual(subclass.int, 2)
        XCTAssertEqual(subclass.string, "b")
        let subclassData: Data = try subclass.encoded()
        let copy = try TestMainActorSubclass.decoded(from: subclassData)
        XCTAssertEqual(copy.int, 2)
        XCTAssertEqual(copy.string, "b")
    }
    
    /// An attributed inherited type such as `@unchecked Sendable` is a protocol, not a superclass.
    func testAttributedInheritedTypeIsNotSuperclass() throws {
        XCTAssertEqual(try TestUncheckedSendableClass.decoded(from: Data(#"{"int":3}"#.utf8)).int, 3)
        XCTAssertEqual(try TestAnyInheritedClass.decoded(from: Data(#"{"int":4}"#.utf8)).int, 4)
    }
    
    func testCollectionConversionByClosure() throws {
        let expected = Date(timeIntervalSince1970: 1_793_793_600)
        let strings = #"{"ints":["1","2","x"],"scores":{"a":"1","b":"2"},"date":"2026-11-04T12:00:00Z"}"#
        let fromStrings = try TestCollectionConversion.decoded(from: Data(strings.utf8))
        XCTAssertEqual(fromStrings.ints, [1, 2])
        XCTAssertEqual(fromStrings.scores, ["a": 1, "b": 2])
        XCTAssertEqual(fromStrings.date, expected)
        
        let numbers = #"{"ints":[1,2],"scores":{"a":1},"date":1793793600}"#
        let fromNumbers = try TestCollectionConversion.decoded(from: Data(numbers.utf8))
        XCTAssertEqual(fromNumbers.ints, [1, 2])
        XCTAssertEqual(fromNumbers.scores, ["a": 1])
        XCTAssertEqual(fromNumbers.date, expected)
        
        let data: Data = try fromStrings.encoded()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["date"] as? String, "2026-11-04T12:00:00Z")
        XCTAssertEqual(try TestCollectionConversion.decoded(from: data).date, expected)
    }
    
    func testCustomDecodeReturningNil() throws {
        XCTAssertThrowsError(try TestCustomDecodeReturnsNil.decoded(from: Data("{}".utf8))) { error in
            guard case DecodingError.valueNotFound = error else {
                return XCTFail("expected valueNotFound, got \(error)")
            }
        }
    }
    
    func testCustomEncodeNilRequired() {
        XCTAssertThrowsError(try TestCustomEncodeNilRequired(required: nil).encoded() as Data) { error in
            guard case EncodingError.invalidValue = error else {
                return XCTFail("expected invalidValue, got \(error)")
            }
        }
        let data: Data = try! TestCustomEncodeNilRequired(required: 5).encoded()
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"required":5}"#)
    }
    
    /// The generated `encode(to:)` must not open a keyed container after the closure has opened a single value container.
    /// JSONEncoder stops the process with a precondition failure when two different containers are opened on one encoder.
    func testCustomEncodeWithSingleValueContainer() throws {
        let data: Data = try TestCustomEncodeSingleValueContainer(value: "a").encoded()
        XCTAssertEqual(String(data: data, encoding: .utf8), #""a""#)
    }
    
    func testCustomEncodeWithUnkeyedContainer() throws {
        let data: Data = try TestCustomEncodeUnkeyedContainer(value: [1, 2]).encoded()
        XCTAssertEqual(String(data: data, encoding: .utf8), "[1,2]")
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
