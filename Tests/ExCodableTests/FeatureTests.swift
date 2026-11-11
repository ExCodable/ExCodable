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
    
    func testNestedKeysNotFound() {
        let json = Data(#"{"int":404,"nested":{"no-nested":{"string": "Not Found"}}}"#.utf8)
        XCTAssertThrowsError(_ = try TestNestedKeys.decoded(from: json)) { error in
            if case let DecodingError.keyNotFound(codingKey, context) = error {
                print("DecodingError.keyNotFound(\(codingKey), \(context))")
            }
            else {
                print("NOT DecodingError.keyNotFound: \(error)")
                XCTFail()
            }
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
            "float16":  "\#(TestFloat16(1.16))",
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
                                                         float16:   TestFloat16(1.16), // as text: "1.1601562" for a Float16, "1.16" for a Float
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
    
    private var tooLargeForTestFloat16: String {
        #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
        return "70000"
        #else
        return "1e40"
        #endif
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
            // `float16` is a number that its type can not hold. 70000 is too large for a `Float16`, and 1e40 for a `Float`, which
            // takes the place of `Float16` on Intel macOS.
            #"""
            {"int8":999,"uint":-1,"double":"1e400","float16":\#(tooLargeForTestFloat16),"bool":"maybe","string":[],
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
            if case let DecodingError.keyNotFound(codingKey, context) = error {
                print("DecodingError.keyNotFound(\(codingKey), \(context))")
            }
            else {
                print("NOT DecodingError.keyNotFound: \(error)")
                XCTFail()
            }
        }
        
        XCTAssertThrowsError(try TestMatrixRequiredStrict.decoded(from: noKeyData)) { error in
            if case let DecodingError.keyNotFound(codingKey, context) = error {
                print("DecodingError.keyNotFound(\(codingKey), \(context))")
            }
            else {
                print("NOT DecodingError.keyNotFound: \(error)")
                XCTFail()
            }
        }
        
        XCTAssertThrowsError(try TestMatrixRequiredPermissive.decoded(from: typeMismatchData)) { error in
            if case let DecodingError.typeMismatch(codingKey, context) = error {
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
        XCTAssertEqual(thrown(TestEnumRequired.self,         #"{"v":9}"#), "dataCorrupted", "required")
        XCTAssertEqual(thrown(TestEnumRequiredStrict.self,   #"{"v":9}"#), "dataCorrupted", "required/strict")
        XCTAssertNil(  thrown(TestEnumOptional.self,         #"{"v":9}"#),                  "optional")
        XCTAssertEqual(thrown(TestEnumOptionalStrict.self,   #"{"v":9}"#), "dataCorrupted", "optional/strict")
        XCTAssertNil(  thrown(TestEnumDefault.self,          #"{"v":9}"#),                  "default")
        
        // String enum: `"z"` is a String that is not a case.
        XCTAssertEqual(thrown(TestStringEnumRequired.self,       #"{"v":"z"}"#), "dataCorrupted", "required")
        XCTAssertEqual(thrown(TestStringEnumRequiredStrict.self, #"{"v":"z"}"#), "dataCorrupted", "required/strict")
        XCTAssertNil(  thrown(TestStringEnumOptional.self,       #"{"v":"z"}"#),                  "optional")
        XCTAssertEqual(thrown(TestStringEnumOptionalStrict.self, #"{"v":"z"}"#), "dataCorrupted", "optional/strict")
        XCTAssertNil(  thrown(TestStringEnumDefault.self,        #"{"v":"z"}"#),                  "default")
        
        // A wrong JSON type is a `typeMismatch`, and `strictType` is what makes an optional property report it.
        XCTAssertEqual(thrown(TestEnumRequired.self,             #"{"v":"x"}"#), "typeMismatch", "required")
        XCTAssertNil(  thrown(TestEnumOptional.self,             #"{"v":"x"}"#),                 "optional")
        XCTAssertEqual(thrown(TestEnumOptionalStrict.self,       #"{"v":"x"}"#), "typeMismatch", "optional/strict")
        XCTAssertEqual(thrown(TestStringEnumRequired.self,       #"{"v":[1]}"#), "typeMismatch", "required")
        XCTAssertNil(  thrown(TestStringEnumOptional.self,       #"{"v":[1]}"#),                 "optional")
        XCTAssertEqual(thrown(TestStringEnumOptionalStrict.self, #"{"v":[1]}"#), "typeMismatch", "optional/strict")
        
        // The builtin conversion turns `true` and `1` into the strings "true" and "1". They are strings, just not cases, so it is a value error.
        XCTAssertEqual(thrown(TestStringEnumRequired.self,       #"{"v":true}"#), "typeMismatch", "required")
        XCTAssertEqual(thrown(TestStringEnumOptionalStrict.self, #"{"v":true}"#), "typeMismatch",  "optional/strict")
        XCTAssertEqual(thrown(TestStringEnumRequired.self,       #"{"v":1}"#),    "typeMismatch",  "required")
        
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
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":{"b":9}}"#),   "dataCorrupted", "invalid enum value")
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":{"b":"x"}}"#), "typeMismatch",  "wrong JSON type")
        XCTAssertEqual(thrown(TestNestedStringRequired.self, #"{"a":{"b":[1]}}"#), "typeMismatch",  "wrong JSON type")
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":{"b":null}}"#), "valueNotFound", "null")
        XCTAssertEqual(thrown(TestNestedEnumOptionalStrict.self, #"{"a":{"b":9}}"#), "dataCorrupted", "optional/strict invalid enum value")
        XCTAssertEqual(thrown(TestNestedEnumOptionalStrict.self, #"{"a":{"b":"x"}}"#), "typeMismatch", "optional/strict wrong JSON type")
        
        // The path is really missing, so `keyNotFound` is the right answer.
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":{}}"#), "keyNotFound", "b missing")
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{}"#),       "keyNotFound", "a missing")
        XCTAssertEqual(thrown(TestNestedEnumRequired.self,  #"{"a":1}"#),  "keyNotFound", "a is not an object")
        
        // It still decodes.
        XCTAssertNil(thrown(TestNestedEnumRequired.self, #"{"a":{"b":1}}"#))
        
        // Alternative keys: the second key has the value but it is wrong, and the first key is simply absent.
        XCTAssertEqual(thrown(TestNestedAlternativeKeys.self, #"{"a":{"b":9}}"#), "dataCorrupted", "alternative keys")
        XCTAssertNil(  thrown(TestNestedAlternativeKeys.self, #"{"a":{"b":1}}"#))
    }
    
    /// A string reads as a number only when the whole string is a decimal number, with an optional sign and fraction.
    /// A fraction is cut off toward zero, like a JSON number. Anything else is not a number: it does not turn into `0`,
    /// and it does not lose its tail (`"12abc"` is not `12`, and `"1,000"` is not `1`).
    func testNumberWrittenAsString() throws {
        func ok(_ text: String, line: UInt = #line) -> String { #"{"v":"\#(text)"}"# }
        
        // What reads as a number, with its fraction cut off toward zero.
        for (text, expected) in [("12", 12), ("12.9", 12), ("-12.9", -12), ("+12", 12), ("00012", 12), ("0", 0), ("-0.9", 0)] as [(String, Int)] {
            XCTAssertEqual(try TestNumberIntRequired.decoded(from: Data(ok(text).utf8)).v, expected, "Int \"\(text)\"")
            XCTAssertEqual(try TestNumberInt64Required.decoded(from: Data(ok(text).utf8)).v, Int64(expected), "Int64 \"\(text)\"")
            XCTAssertEqual(try TestNumberInt16Required.decoded(from: Data(ok(text).utf8)).v, Int16(expected), "Int16 \"\(text)\"")
        }
        
        // What is not a number: a required property reports a type error, an optional property has no value, and nothing becomes 0.
        for text in ["12.", "12abc", "abc", "1,000", "0x10", "-", "+", ".5", "-.5", "1e3", "1.5e3", "1E2", " 12 ", "12 34", "12.9.1", "--5", "1_000", ""] {
            XCTAssertEqual(thrown(TestNumberIntRequired.self,    ok(text)), "typeMismatch", "Int required \"\(text)\"")
            XCTAssertEqual(thrown(TestNumberInt64Required.self,  ok(text)), "typeMismatch", "Int64 required \"\(text)\"")
            XCTAssertEqual(thrown(TestNumberInt16Required.self,  ok(text)), "typeMismatch", "Int16 required \"\(text)\"")
            XCTAssertEqual(thrown(TestNumberUInt8Required.self,  ok(text)), "typeMismatch", "UInt8 required \"\(text)\"")
            XCTAssertNil(try TestNumberIntOptional.decoded(from: Data(ok(text).utf8)).v,    "Int optional \"\(text)\"")
            XCTAssertNil(try TestNumberInt16Optional.decoded(from: Data(ok(text).utf8)).v,  "Int16 optional \"\(text)\"")
            XCTAssertNil(try TestNumberUInt8Optional.decoded(from: Data(ok(text).utf8)).v,  "UInt8 optional \"\(text)\"")
        }
        
        // A string is read at the width of the property.
        XCTAssertEqual(try TestNumberIntRequired.decoded(from: Data(ok("9223372036854775807").utf8)).v, .max)
        XCTAssertEqual(thrown(TestNumberIntRequired.self,   ok("9223372036854775808")), "typeMismatch")
        XCTAssertEqual(thrown(TestNumberIntRequired.self,   ok("-9223372036854775809")), "typeMismatch")
        XCTAssertEqual(try TestNumberUInt8Required.decoded(from: Data(ok("255").utf8)).v, 255)
        XCTAssertEqual(thrown(TestNumberUInt8Required.self, ok("256")), "typeMismatch")
        XCTAssertEqual(thrown(TestNumberUInt8Required.self, ok("-1")),  "typeMismatch")
        
        // Bool reads a number from a string by the same rule. The words and the empty string keep their meaning.
        XCTAssertEqual(try TestStringNumberBool.decoded(from: Data(ok("12.9").utf8)).v, true)
        XCTAssertEqual(try TestStringNumberBool.decoded(from: Data(ok("0.0").utf8)).v, false)
        XCTAssertEqual(try TestStringNumberBool.decoded(from: Data(ok("yes").utf8)).v, true)
        XCTAssertEqual(try TestStringNumberBool.decoded(from: Data(ok("").utf8)).v, false)
        for text in ["12abc", "abc", "1,000", "0x10", "-", ".5", "1e3", " 12 "] {
            XCTAssertEqual(thrown(TestStringNumberBool.self, ok(text)), "typeMismatch", "Bool \"\(text)\"")
        }
    }
    
    /// A JSON number with a fraction is cut off toward zero for every integer width, and the cut-off value must still fit.
    func testFractionIsCutOffForEveryWidth() throws {
        func number(_ text: String) -> Data { Data(#"{"v":\#(text)}"#.utf8) }
        
        // Int16 once read the number as an Int8 and failed on every fraction.
        XCTAssertEqual(try TestNumberInt16Required.decoded(from: number("12.9")).v,       12)
        XCTAssertEqual(try TestNumberInt16Required.decoded(from: number("200.9")).v,      200)
        XCTAssertEqual(try TestNumberInt16Required.decoded(from: number("1000.5")).v,     1000)
        XCTAssertEqual(try TestNumberInt16Optional.decoded(from: number("12.9")).v,       12)
        XCTAssertEqual(try TestNumberInt16Required.decoded(from: number("32767.9")).v,    32767)
        XCTAssertEqual(try TestNumberInt16Required.decoded(from: number("-32768.9")).v,   -32768)
        XCTAssertEqual(thrown(TestNumberInt16Required.self, #"{"v":32768.0}"#),  "dataCorrupted")
        XCTAssertEqual(thrown(TestNumberInt16Required.self, #"{"v":-32769.0}"#), "dataCorrupted")
        
        XCTAssertEqual(try TestNumberInt8Required.decoded(from: number("127.9")).v,        127)
        XCTAssertEqual(try TestNumberInt8Required.decoded(from: number("-128.9")).v,       -128)
        XCTAssertEqual(thrown(TestNumberInt8Required.self, #"{"v":128.0}"#),  "dataCorrupted")
        XCTAssertEqual(thrown(TestNumberInt8Required.self, #"{"v":-129.0}"#), "dataCorrupted")
        
        XCTAssertEqual(try TestNumberInt32Required.decoded(from: number("2147483647.9")).v, 2147483647)
        XCTAssertEqual(thrown(TestNumberInt32Required.self, #"{"v":2147483648.0}"#), "dataCorrupted")
        
        XCTAssertEqual(try TestNumberInt64Required.decoded(from: number("9223372036854775807.5")).v, .max)
        XCTAssertEqual(try TestNumberInt64Required.decoded(from: number("-9223372036854775808.5")).v, .min)
        XCTAssertEqual(thrown(TestNumberInt64Required.self, #"{"v":9223372036854775808.0}"#), "dataCorrupted")
        
        // An unsigned width takes a fraction that rounds to 0, and not a negative whole number.
        XCTAssertEqual(try TestNumberUInt8Required.decoded(from: number("255.9")).v,       255)
        XCTAssertEqual(try TestNumberUInt8Required.decoded(from: number("-0.9")).v,       0)
        XCTAssertEqual(thrown(TestNumberUInt8Required.self, #"{"v":256.0}"#), "dataCorrupted")
        XCTAssertEqual(thrown(TestNumberUInt8Required.self, #"{"v":-1.0}"#),  "dataCorrupted")
        XCTAssertEqual(try TestNumberUInt16Required.decoded(from: number("65535.9")).v,    65535)
        XCTAssertEqual(try TestNumberUInt32Required.decoded(from: number("4294967295.9")).v, 4294967295)
        XCTAssertEqual(try TestNumberUInt64Required.decoded(from: number("18446744073709551615.5")).v, .max)
        XCTAssertEqual(thrown(TestNumberUInt64Required.self, #"{"v":18446744073709551616}"#), "dataCorrupted")
    }
    
    /// `Int128` and `UInt128` are not in `Decimal`'s range, so a string is read by its digits instead. The same rule applies.
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    func testNumberWrittenAsStringFor128Bit() throws {
        func text(_ value: String) -> Data { Data(#"{"v":"\#(value)"}"#.utf8) }
        
        XCTAssertEqual(try TestStringNumberInt128.decoded(from: text("170141183460469231731687303715884105727")).v, .max)
        XCTAssertEqual(try TestStringNumberInt128.decoded(from: text("-170141183460469231731687303715884105728")).v, .min)
        XCTAssertEqual(try TestStringNumberInt128.decoded(from: text("12.9")).v, 12)
        XCTAssertEqual(try TestStringNumberUInt128.decoded(from: text("340282366920938463463374607431768211455")).v, .max)
        
        // One past the range is not a number of this width.
        XCTAssertEqual(thrown(TestStringNumberInt128.self,  #"{"v":"170141183460469231731687303715884105728"}"#),  "typeMismatch")
        XCTAssertEqual(thrown(TestStringNumberInt128.self,  #"{"v":"-170141183460469231731687303715884105729"}"#), "typeMismatch")
        XCTAssertEqual(thrown(TestStringNumberUInt128.self, #"{"v":"340282366920938463463374607431768211456"}"#),  "typeMismatch")
        XCTAssertEqual(thrown(TestStringNumberUInt128.self, #"{"v":"-1"}"#), "typeMismatch")
        
        for value in ["12abc", "abc", "1,000", "1e3", ".5", " 12 "] {
            XCTAssertEqual(thrown(TestStringNumberInt128.self, #"{"v":"\#(value)"}"#), "typeMismatch", "Int128 \"\(value)\"")
        }
        
        // A JSON number keeps every digit up to 2^127: it is not rounded through a Double on the way.
        XCTAssertEqual(try TestStringNumberInt128.decoded(from: Data(#"{"v":9007199254740993}"#.utf8)).v, 9007199254740993)
        XCTAssertEqual(try TestStringNumberInt128.decoded(from: Data(#"{"v":12.9}"#.utf8)).v, 12)
    }
    
    /// A JSON number, or a numeric string, that does not fit the property's type is a value error, not a type error:
    /// an optional property becomes `nil`, a required property throws `valueNotFound`, and `default` replaces it.
    /// `strictType` does not change that. JSONDecoder reports the overflow as a `dataCorrupted` that says the JSON is
    /// invalid, which it is not, so it must not reach the caller.
    func testNumberThatDoesNotFit() throws {
        // Int
        XCTAssertNil(thrown(TestNumberIntRequired.self, #"{"v":9223372036854775807}"#), "Int required, 9223372036854775807")
        XCTAssertNil(thrown(TestNumberIntRequired.self, #"{"v":-9223372036854775808}"#), "Int required, -9223372036854775808")
        XCTAssertEqual(thrown(TestNumberIntRequired.self,       #"{"v":9223372036854775808}"#), "dataCorrupted", "Int required 9223372036854775808")
        XCTAssertEqual(thrown(TestNumberIntOptional.self,       #"{"v":9223372036854775808}"#), nil, "Int optional 9223372036854775808")
        XCTAssertEqual(thrown(TestNumberIntOptionalStrict.self, #"{"v":9223372036854775808}"#), "dataCorrupted", "Int optional/strict 9223372036854775808")
        XCTAssertEqual(thrown(TestNumberIntDefault.self,        #"{"v":9223372036854775808}"#), nil, "Int default 9223372036854775808")
        XCTAssertEqual(thrown(TestNumberIntRequired.self,       #"{"v":-9223372036854775809}"#), "dataCorrupted", "Int required -9223372036854775809")
        XCTAssertEqual(thrown(TestNumberIntOptional.self,       #"{"v":-9223372036854775809}"#), nil, "Int optional -9223372036854775809")
        XCTAssertEqual(thrown(TestNumberIntOptionalStrict.self, #"{"v":-9223372036854775809}"#), "dataCorrupted", "Int optional/strict -9223372036854775809")
        XCTAssertEqual(thrown(TestNumberIntDefault.self,        #"{"v":-9223372036854775809}"#), nil, "Int default -9223372036854775809")
        XCTAssertEqual(thrown(TestNumberIntRequired.self,       #"{"v":"9223372036854775808"}"#), "typeMismatch", "Int required \"9223372036854775808\"")
        XCTAssertEqual(thrown(TestNumberIntOptional.self,       #"{"v":"9223372036854775808"}"#), nil, "Int optional \"9223372036854775808\"")
        XCTAssertEqual(thrown(TestNumberIntOptionalStrict.self, #"{"v":"9223372036854775808"}"#), "typeMismatch", "Int optional/strict \"9223372036854775808\"")
        XCTAssertEqual(thrown(TestNumberIntDefault.self,        #"{"v":"9223372036854775808"}"#), nil, "Int default \"9223372036854775808\"")
        XCTAssertEqual(thrown(TestNumberIntRequired.self,       #"{"v":1e30}"#), "dataCorrupted", "Int required 1e30")
        XCTAssertEqual(thrown(TestNumberIntOptional.self,       #"{"v":1e30}"#), nil, "Int optional 1e30")
        XCTAssertEqual(thrown(TestNumberIntOptionalStrict.self, #"{"v":1e30}"#), "dataCorrupted", "Int optional/strict 1e30")
        XCTAssertEqual(thrown(TestNumberIntDefault.self,        #"{"v":1e30}"#), nil, "Int default 1e30")
        // Int8
        XCTAssertNil(thrown(TestNumberInt8Required.self, #"{"v":127}"#), "Int8 required, 127")
        XCTAssertNil(thrown(TestNumberInt8Required.self, #"{"v":-128}"#), "Int8 required, -128")
        XCTAssertEqual(thrown(TestNumberInt8Required.self,       #"{"v":128}"#), "dataCorrupted", "Int8 required 128")
        XCTAssertEqual(thrown(TestNumberInt8Optional.self,       #"{"v":128}"#), nil, "Int8 optional 128")
        XCTAssertEqual(thrown(TestNumberInt8OptionalStrict.self, #"{"v":128}"#), "dataCorrupted", "Int8 optional/strict 128")
        XCTAssertEqual(thrown(TestNumberInt8Default.self,        #"{"v":128}"#), nil, "Int8 default 128")
        XCTAssertEqual(thrown(TestNumberInt8Required.self,       #"{"v":-129}"#), "dataCorrupted", "Int8 required -129")
        XCTAssertEqual(thrown(TestNumberInt8Optional.self,       #"{"v":-129}"#), nil, "Int8 optional -129")
        XCTAssertEqual(thrown(TestNumberInt8OptionalStrict.self, #"{"v":-129}"#), "dataCorrupted", "Int8 optional/strict -129")
        XCTAssertEqual(thrown(TestNumberInt8Default.self,        #"{"v":-129}"#), nil, "Int8 default -129")
        XCTAssertEqual(thrown(TestNumberInt8Required.self,       #"{"v":300.7}"#), "dataCorrupted", "Int8 required 300.7")
        XCTAssertEqual(thrown(TestNumberInt8Optional.self,       #"{"v":300.7}"#), nil, "Int8 optional 300.7")
        XCTAssertEqual(thrown(TestNumberInt8OptionalStrict.self, #"{"v":300.7}"#), "dataCorrupted", "Int8 optional/strict 300.7")
        XCTAssertEqual(thrown(TestNumberInt8Default.self,        #"{"v":300.7}"#), nil, "Int8 default 300.7")
        XCTAssertEqual(thrown(TestNumberInt8Required.self,       #"{"v":"300"}"#), "typeMismatch", "Int8 required \"300\"")
        XCTAssertEqual(thrown(TestNumberInt8Optional.self,       #"{"v":"300"}"#), nil, "Int8 optional \"300\"")
        XCTAssertEqual(thrown(TestNumberInt8OptionalStrict.self, #"{"v":"300"}"#), "typeMismatch", "Int8 optional/strict \"300\"")
        XCTAssertEqual(thrown(TestNumberInt8Default.self,        #"{"v":"300"}"#), nil, "Int8 default \"300\"")
        XCTAssertEqual(thrown(TestNumberInt8Required.self,       #"{"v":"1e3"}"#), "typeMismatch", "Int8 required \"1e3\"")
        XCTAssertEqual(thrown(TestNumberInt8Optional.self,       #"{"v":"1e3"}"#), nil, "Int8 optional \"1e3\"")
        XCTAssertEqual(thrown(TestNumberInt8OptionalStrict.self, #"{"v":"1e3"}"#), "typeMismatch", "Int8 optional/strict \"1e3\"")
        XCTAssertEqual(thrown(TestNumberInt8Default.self,        #"{"v":"1e3"}"#), nil, "Int8 default \"1e3\"")
        // Int16
        XCTAssertNil(thrown(TestNumberInt16Required.self, #"{"v":32767}"#), "Int16 required, 32767")
        XCTAssertNil(thrown(TestNumberInt16Required.self, #"{"v":-32768}"#), "Int16 required, -32768")
        XCTAssertEqual(thrown(TestNumberInt16Required.self,       #"{"v":32768}"#), "dataCorrupted", "Int16 required 32768")
        XCTAssertEqual(thrown(TestNumberInt16Optional.self,       #"{"v":32768}"#), nil, "Int16 optional 32768")
        XCTAssertEqual(thrown(TestNumberInt16OptionalStrict.self, #"{"v":32768}"#), "dataCorrupted", "Int16 optional/strict 32768")
        XCTAssertEqual(thrown(TestNumberInt16Default.self,        #"{"v":32768}"#), nil, "Int16 default 32768")
        XCTAssertEqual(thrown(TestNumberInt16Required.self,       #"{"v":-32769}"#), "dataCorrupted", "Int16 required -32769")
        XCTAssertEqual(thrown(TestNumberInt16Optional.self,       #"{"v":-32769}"#), nil, "Int16 optional -32769")
        XCTAssertEqual(thrown(TestNumberInt16OptionalStrict.self, #"{"v":-32769}"#), "dataCorrupted", "Int16 optional/strict -32769")
        XCTAssertEqual(thrown(TestNumberInt16Default.self,        #"{"v":-32769}"#), nil, "Int16 default -32769")
        XCTAssertEqual(thrown(TestNumberInt16Required.self,       #"{"v":"40000"}"#), "typeMismatch", "Int16 required \"40000\"")
        XCTAssertEqual(thrown(TestNumberInt16Optional.self,       #"{"v":"40000"}"#), nil, "Int16 optional \"40000\"")
        XCTAssertEqual(thrown(TestNumberInt16OptionalStrict.self, #"{"v":"40000"}"#), "typeMismatch", "Int16 optional/strict \"40000\"")
        XCTAssertEqual(thrown(TestNumberInt16Default.self,        #"{"v":"40000"}"#), nil, "Int16 default \"40000\"")
        // Int32
        XCTAssertNil(thrown(TestNumberInt32Required.self, #"{"v":2147483647}"#), "Int32 required, 2147483647")
        XCTAssertNil(thrown(TestNumberInt32Required.self, #"{"v":-2147483648}"#), "Int32 required, -2147483648")
        XCTAssertEqual(thrown(TestNumberInt32Required.self,       #"{"v":2147483648}"#), "dataCorrupted", "Int32 required 2147483648")
        XCTAssertEqual(thrown(TestNumberInt32Optional.self,       #"{"v":2147483648}"#), nil, "Int32 optional 2147483648")
        XCTAssertEqual(thrown(TestNumberInt32OptionalStrict.self, #"{"v":2147483648}"#), "dataCorrupted", "Int32 optional/strict 2147483648")
        XCTAssertEqual(thrown(TestNumberInt32Default.self,        #"{"v":2147483648}"#), nil, "Int32 default 2147483648")
        XCTAssertEqual(thrown(TestNumberInt32Required.self,       #"{"v":-2147483649}"#), "dataCorrupted", "Int32 required -2147483649")
        XCTAssertEqual(thrown(TestNumberInt32Optional.self,       #"{"v":-2147483649}"#), nil, "Int32 optional -2147483649")
        XCTAssertEqual(thrown(TestNumberInt32OptionalStrict.self, #"{"v":-2147483649}"#), "dataCorrupted", "Int32 optional/strict -2147483649")
        XCTAssertEqual(thrown(TestNumberInt32Default.self,        #"{"v":-2147483649}"#), nil, "Int32 default -2147483649")
        XCTAssertEqual(thrown(TestNumberInt32Required.self,       #"{"v":"3000000000"}"#), "typeMismatch", "Int32 required \"3000000000\"")
        XCTAssertEqual(thrown(TestNumberInt32Optional.self,       #"{"v":"3000000000"}"#), nil, "Int32 optional \"3000000000\"")
        XCTAssertEqual(thrown(TestNumberInt32OptionalStrict.self, #"{"v":"3000000000"}"#), "typeMismatch", "Int32 optional/strict \"3000000000\"")
        XCTAssertEqual(thrown(TestNumberInt32Default.self,        #"{"v":"3000000000"}"#), nil, "Int32 default \"3000000000\"")
        // Int64
        XCTAssertNil(thrown(TestNumberInt64Required.self, #"{"v":9223372036854775807}"#), "Int64 required, 9223372036854775807")
        XCTAssertNil(thrown(TestNumberInt64Required.self, #"{"v":-9223372036854775808}"#), "Int64 required, -9223372036854775808")
        XCTAssertEqual(thrown(TestNumberInt64Required.self,       #"{"v":9223372036854775808}"#), "dataCorrupted", "Int64 required 9223372036854775808")
        XCTAssertEqual(thrown(TestNumberInt64Optional.self,       #"{"v":9223372036854775808}"#), nil, "Int64 optional 9223372036854775808")
        XCTAssertEqual(thrown(TestNumberInt64OptionalStrict.self, #"{"v":9223372036854775808}"#), "dataCorrupted", "Int64 optional/strict 9223372036854775808")
        XCTAssertEqual(thrown(TestNumberInt64Default.self,        #"{"v":9223372036854775808}"#), nil, "Int64 default 9223372036854775808")
        XCTAssertEqual(thrown(TestNumberInt64Required.self,       #"{"v":-9223372036854775809}"#), "dataCorrupted", "Int64 required -9223372036854775809")
        XCTAssertEqual(thrown(TestNumberInt64Optional.self,       #"{"v":-9223372036854775809}"#), nil, "Int64 optional -9223372036854775809")
        XCTAssertEqual(thrown(TestNumberInt64OptionalStrict.self, #"{"v":-9223372036854775809}"#), "dataCorrupted", "Int64 optional/strict -9223372036854775809")
        XCTAssertEqual(thrown(TestNumberInt64Default.self,        #"{"v":-9223372036854775809}"#), nil, "Int64 default -9223372036854775809")
        XCTAssertEqual(thrown(TestNumberInt64Required.self,       #"{"v":"9223372036854775808"}"#), "typeMismatch", "Int64 required \"9223372036854775808\"")
        XCTAssertEqual(thrown(TestNumberInt64Optional.self,       #"{"v":"9223372036854775808"}"#), nil, "Int64 optional \"9223372036854775808\"")
        XCTAssertEqual(thrown(TestNumberInt64OptionalStrict.self, #"{"v":"9223372036854775808"}"#), "typeMismatch", "Int64 optional/strict \"9223372036854775808\"")
        XCTAssertEqual(thrown(TestNumberInt64Default.self,        #"{"v":"9223372036854775808"}"#), nil, "Int64 default \"9223372036854775808\"")
        XCTAssertEqual(thrown(TestNumberInt64Required.self,       #"{"v":1e30}"#), "dataCorrupted", "Int64 required 1e30")
        XCTAssertEqual(thrown(TestNumberInt64Optional.self,       #"{"v":1e30}"#), nil, "Int64 optional 1e30")
        XCTAssertEqual(thrown(TestNumberInt64OptionalStrict.self, #"{"v":1e30}"#), "dataCorrupted", "Int64 optional/strict 1e30")
        XCTAssertEqual(thrown(TestNumberInt64Default.self,        #"{"v":1e30}"#), nil, "Int64 default 1e30")
        // UInt
        XCTAssertNil(thrown(TestNumberUIntRequired.self, #"{"v":18446744073709551615}"#), "UInt required, 18446744073709551615")
        XCTAssertNil(thrown(TestNumberUIntRequired.self, #"{"v":0}"#), "UInt required, 0")
        XCTAssertEqual(thrown(TestNumberUIntRequired.self,       #"{"v":-1}"#), "dataCorrupted", "UInt required -1")
        XCTAssertEqual(thrown(TestNumberUIntOptional.self,       #"{"v":-1}"#), nil, "UInt optional -1")
        XCTAssertEqual(thrown(TestNumberUIntOptionalStrict.self, #"{"v":-1}"#), "dataCorrupted", "UInt optional/strict -1")
        XCTAssertEqual(thrown(TestNumberUIntDefault.self,        #"{"v":-1}"#), nil, "UInt default -1")
        XCTAssertEqual(thrown(TestNumberUIntRequired.self,       #"{"v":18446744073709551616}"#), "dataCorrupted", "UInt required 18446744073709551616")
        XCTAssertEqual(thrown(TestNumberUIntOptional.self,       #"{"v":18446744073709551616}"#), nil, "UInt optional 18446744073709551616")
        XCTAssertEqual(thrown(TestNumberUIntOptionalStrict.self, #"{"v":18446744073709551616}"#), "dataCorrupted", "UInt optional/strict 18446744073709551616")
        XCTAssertEqual(thrown(TestNumberUIntDefault.self,        #"{"v":18446744073709551616}"#), nil, "UInt default 18446744073709551616")
        XCTAssertEqual(thrown(TestNumberUIntRequired.self,       #"{"v":"18446744073709551616"}"#), "typeMismatch", "UInt required \"18446744073709551616\"")
        XCTAssertEqual(thrown(TestNumberUIntOptional.self,       #"{"v":"18446744073709551616"}"#), nil, "UInt optional \"18446744073709551616\"")
        XCTAssertEqual(thrown(TestNumberUIntOptionalStrict.self, #"{"v":"18446744073709551616"}"#), "typeMismatch", "UInt optional/strict \"18446744073709551616\"")
        XCTAssertEqual(thrown(TestNumberUIntDefault.self,        #"{"v":"18446744073709551616"}"#), nil, "UInt default \"18446744073709551616\"")
        XCTAssertEqual(thrown(TestNumberUIntRequired.self,       #"{"v":"-1"}"#), "typeMismatch", "UInt required \"-1\"")
        XCTAssertEqual(thrown(TestNumberUIntOptional.self,       #"{"v":"-1"}"#), nil, "UInt optional \"-1\"")
        XCTAssertEqual(thrown(TestNumberUIntOptionalStrict.self, #"{"v":"-1"}"#), "typeMismatch", "UInt optional/strict \"-1\"")
        XCTAssertEqual(thrown(TestNumberUIntDefault.self,        #"{"v":"-1"}"#), nil, "UInt default \"-1\"")
        // UInt8
        XCTAssertNil(thrown(TestNumberUInt8Required.self, #"{"v":255}"#), "UInt8 required, 255")
        XCTAssertNil(thrown(TestNumberUInt8Required.self, #"{"v":0}"#), "UInt8 required, 0")
        XCTAssertEqual(thrown(TestNumberUInt8Required.self,       #"{"v":256}"#), "dataCorrupted", "UInt8 required 256")
        XCTAssertEqual(thrown(TestNumberUInt8Optional.self,       #"{"v":256}"#), nil, "UInt8 optional 256")
        XCTAssertEqual(thrown(TestNumberUInt8OptionalStrict.self, #"{"v":256}"#), "dataCorrupted", "UInt8 optional/strict 256")
        XCTAssertEqual(thrown(TestNumberUInt8Default.self,        #"{"v":256}"#), nil, "UInt8 default 256")
        XCTAssertEqual(thrown(TestNumberUInt8Required.self,       #"{"v":-1}"#), "dataCorrupted", "UInt8 required -1")
        XCTAssertEqual(thrown(TestNumberUInt8Optional.self,       #"{"v":-1}"#), nil, "UInt8 optional -1")
        XCTAssertEqual(thrown(TestNumberUInt8OptionalStrict.self, #"{"v":-1}"#), "dataCorrupted", "UInt8 optional/strict -1")
        XCTAssertEqual(thrown(TestNumberUInt8Default.self,        #"{"v":-1}"#), nil, "UInt8 default -1")
        XCTAssertEqual(thrown(TestNumberUInt8Required.self,       #"{"v":"256"}"#), "typeMismatch", "UInt8 required \"256\"")
        XCTAssertEqual(thrown(TestNumberUInt8Optional.self,       #"{"v":"256"}"#), nil, "UInt8 optional \"256\"")
        XCTAssertEqual(thrown(TestNumberUInt8OptionalStrict.self, #"{"v":"256"}"#), "typeMismatch", "UInt8 optional/strict \"256\"")
        XCTAssertEqual(thrown(TestNumberUInt8Default.self,        #"{"v":"256"}"#), nil, "UInt8 default \"256\"")
        // UInt16
        XCTAssertNil(thrown(TestNumberUInt16Required.self, #"{"v":65535}"#), "UInt16 required, 65535")
        XCTAssertNil(thrown(TestNumberUInt16Required.self, #"{"v":0}"#), "UInt16 required, 0")
        XCTAssertEqual(thrown(TestNumberUInt16Required.self,       #"{"v":65536}"#), "dataCorrupted", "UInt16 required 65536")
        XCTAssertEqual(thrown(TestNumberUInt16Optional.self,       #"{"v":65536}"#), nil, "UInt16 optional 65536")
        XCTAssertEqual(thrown(TestNumberUInt16OptionalStrict.self, #"{"v":65536}"#), "dataCorrupted", "UInt16 optional/strict 65536")
        XCTAssertEqual(thrown(TestNumberUInt16Default.self,        #"{"v":65536}"#), nil, "UInt16 default 65536")
        XCTAssertEqual(thrown(TestNumberUInt16Required.self,       #"{"v":-1}"#), "dataCorrupted", "UInt16 required -1")
        XCTAssertEqual(thrown(TestNumberUInt16Optional.self,       #"{"v":-1}"#), nil, "UInt16 optional -1")
        XCTAssertEqual(thrown(TestNumberUInt16OptionalStrict.self, #"{"v":-1}"#), "dataCorrupted", "UInt16 optional/strict -1")
        XCTAssertEqual(thrown(TestNumberUInt16Default.self,        #"{"v":-1}"#), nil, "UInt16 default -1")
        XCTAssertEqual(thrown(TestNumberUInt16Required.self,       #"{"v":"70000"}"#), "typeMismatch", "UInt16 required \"70000\"")
        XCTAssertEqual(thrown(TestNumberUInt16Optional.self,       #"{"v":"70000"}"#), nil, "UInt16 optional \"70000\"")
        XCTAssertEqual(thrown(TestNumberUInt16OptionalStrict.self, #"{"v":"70000"}"#), "typeMismatch", "UInt16 optional/strict \"70000\"")
        XCTAssertEqual(thrown(TestNumberUInt16Default.self,        #"{"v":"70000"}"#), nil, "UInt16 default \"70000\"")
        // UInt32
        XCTAssertNil(thrown(TestNumberUInt32Required.self, #"{"v":4294967295}"#), "UInt32 required, 4294967295")
        XCTAssertNil(thrown(TestNumberUInt32Required.self, #"{"v":0}"#), "UInt32 required, 0")
        XCTAssertEqual(thrown(TestNumberUInt32Required.self,       #"{"v":4294967296}"#), "dataCorrupted", "UInt32 required 4294967296")
        XCTAssertEqual(thrown(TestNumberUInt32Optional.self,       #"{"v":4294967296}"#), nil, "UInt32 optional 4294967296")
        XCTAssertEqual(thrown(TestNumberUInt32OptionalStrict.self, #"{"v":4294967296}"#), "dataCorrupted", "UInt32 optional/strict 4294967296")
        XCTAssertEqual(thrown(TestNumberUInt32Default.self,        #"{"v":4294967296}"#), nil, "UInt32 default 4294967296")
        XCTAssertEqual(thrown(TestNumberUInt32Required.self,       #"{"v":-1}"#), "dataCorrupted", "UInt32 required -1")
        XCTAssertEqual(thrown(TestNumberUInt32Optional.self,       #"{"v":-1}"#), nil, "UInt32 optional -1")
        XCTAssertEqual(thrown(TestNumberUInt32OptionalStrict.self, #"{"v":-1}"#), "dataCorrupted", "UInt32 optional/strict -1")
        XCTAssertEqual(thrown(TestNumberUInt32Default.self,        #"{"v":-1}"#), nil, "UInt32 default -1")
        XCTAssertEqual(thrown(TestNumberUInt32Required.self,       #"{"v":"5000000000"}"#), "typeMismatch", "UInt32 required \"5000000000\"")
        XCTAssertEqual(thrown(TestNumberUInt32Optional.self,       #"{"v":"5000000000"}"#), nil, "UInt32 optional \"5000000000\"")
        XCTAssertEqual(thrown(TestNumberUInt32OptionalStrict.self, #"{"v":"5000000000"}"#), "typeMismatch", "UInt32 optional/strict \"5000000000\"")
        XCTAssertEqual(thrown(TestNumberUInt32Default.self,        #"{"v":"5000000000"}"#), nil, "UInt32 default \"5000000000\"")
        // UInt64
        XCTAssertNil(thrown(TestNumberUInt64Required.self, #"{"v":18446744073709551615}"#), "UInt64 required, 18446744073709551615")
        XCTAssertNil(thrown(TestNumberUInt64Required.self, #"{"v":0}"#), "UInt64 required, 0")
        XCTAssertEqual(thrown(TestNumberUInt64Required.self,       #"{"v":18446744073709551616}"#), "dataCorrupted", "UInt64 required 18446744073709551616")
        XCTAssertEqual(thrown(TestNumberUInt64Optional.self,       #"{"v":18446744073709551616}"#), nil, "UInt64 optional 18446744073709551616")
        XCTAssertEqual(thrown(TestNumberUInt64OptionalStrict.self, #"{"v":18446744073709551616}"#), "dataCorrupted", "UInt64 optional/strict 18446744073709551616")
        XCTAssertEqual(thrown(TestNumberUInt64Default.self,        #"{"v":18446744073709551616}"#), nil, "UInt64 default 18446744073709551616")
        XCTAssertEqual(thrown(TestNumberUInt64Required.self,       #"{"v":-1}"#), "dataCorrupted", "UInt64 required -1")
        XCTAssertEqual(thrown(TestNumberUInt64Optional.self,       #"{"v":-1}"#), nil, "UInt64 optional -1")
        XCTAssertEqual(thrown(TestNumberUInt64OptionalStrict.self, #"{"v":-1}"#), "dataCorrupted", "UInt64 optional/strict -1")
        XCTAssertEqual(thrown(TestNumberUInt64Default.self,        #"{"v":-1}"#), nil, "UInt64 default -1")
        XCTAssertEqual(thrown(TestNumberUInt64Required.self,       #"{"v":"18446744073709551616"}"#), "typeMismatch", "UInt64 required \"18446744073709551616\"")
        XCTAssertEqual(thrown(TestNumberUInt64Optional.self,       #"{"v":"18446744073709551616"}"#), nil, "UInt64 optional \"18446744073709551616\"")
        XCTAssertEqual(thrown(TestNumberUInt64OptionalStrict.self, #"{"v":"18446744073709551616"}"#), "typeMismatch", "UInt64 optional/strict \"18446744073709551616\"")
        XCTAssertEqual(thrown(TestNumberUInt64Default.self,        #"{"v":"18446744073709551616"}"#), nil, "UInt64 default \"18446744073709551616\"")
        // Float
        XCTAssertNil(thrown(TestNumberFloatRequired.self, #"{"v":1.5}"#), "Float required, 1.5")
        XCTAssertNil(thrown(TestNumberFloatRequired.self, #"{"v":3.4e38}"#), "Float required, 3.4e38")
        XCTAssertEqual(thrown(TestNumberFloatRequired.self,       #"{"v":1e39}"#), "dataCorrupted", "Float required 1e39")
        XCTAssertEqual(thrown(TestNumberFloatOptional.self,       #"{"v":1e39}"#), nil, "Float optional 1e39")
        XCTAssertEqual(thrown(TestNumberFloatOptionalStrict.self, #"{"v":1e39}"#), "dataCorrupted", "Float optional/strict 1e39")
        XCTAssertEqual(thrown(TestNumberFloatDefault.self,        #"{"v":1e39}"#), nil, "Float default 1e39")
        XCTAssertEqual(thrown(TestNumberFloatRequired.self,       #"{"v":-1e39}"#), "dataCorrupted", "Float required -1e39")
        XCTAssertEqual(thrown(TestNumberFloatOptional.self,       #"{"v":-1e39}"#), nil, "Float optional -1e39")
        XCTAssertEqual(thrown(TestNumberFloatOptionalStrict.self, #"{"v":-1e39}"#), "dataCorrupted", "Float optional/strict -1e39")
        XCTAssertEqual(thrown(TestNumberFloatDefault.self,        #"{"v":-1e39}"#), nil, "Float default -1e39")
        XCTAssertEqual(thrown(TestNumberFloatRequired.self,       #"{"v":1e400}"#), "dataCorrupted", "Float required 1e400")
        XCTAssertEqual(thrown(TestNumberFloatOptional.self,       #"{"v":1e400}"#), nil, "Float optional 1e400")
        XCTAssertEqual(thrown(TestNumberFloatOptionalStrict.self, #"{"v":1e400}"#), "dataCorrupted", "Float optional/strict 1e400")
        XCTAssertEqual(thrown(TestNumberFloatDefault.self,        #"{"v":1e400}"#), nil, "Float default 1e400")
        XCTAssertEqual(thrown(TestNumberFloatRequired.self,       #"{"v":"1e39"}"#), "typeMismatch", "Float required \"1e39\"")
        XCTAssertEqual(thrown(TestNumberFloatOptional.self,       #"{"v":"1e39"}"#), nil, "Float optional \"1e39\"")
        XCTAssertEqual(thrown(TestNumberFloatOptionalStrict.self, #"{"v":"1e39"}"#), "typeMismatch", "Float optional/strict \"1e39\"")
        XCTAssertEqual(thrown(TestNumberFloatDefault.self,        #"{"v":"1e39"}"#), nil, "Float default \"1e39\"")
        // Double
        XCTAssertNil(thrown(TestNumberDoubleRequired.self, #"{"v":1.5}"#), "Double required, 1.5")
        XCTAssertNil(thrown(TestNumberDoubleRequired.self, #"{"v":1.7e308}"#), "Double required, 1.7e308")
        XCTAssertEqual(thrown(TestNumberDoubleRequired.self,       #"{"v":1e400}"#), "dataCorrupted", "Double required 1e400")
        XCTAssertEqual(thrown(TestNumberDoubleOptional.self,       #"{"v":1e400}"#), nil, "Double optional 1e400")
        XCTAssertEqual(thrown(TestNumberDoubleOptionalStrict.self, #"{"v":1e400}"#), "dataCorrupted", "Double optional/strict 1e400")
        XCTAssertEqual(thrown(TestNumberDoubleDefault.self,        #"{"v":1e400}"#), nil, "Double default 1e400")
        XCTAssertEqual(thrown(TestNumberDoubleRequired.self,       #"{"v":-1e400}"#), "dataCorrupted", "Double required -1e400")
        XCTAssertEqual(thrown(TestNumberDoubleOptional.self,       #"{"v":-1e400}"#), nil, "Double optional -1e400")
        XCTAssertEqual(thrown(TestNumberDoubleOptionalStrict.self, #"{"v":-1e400}"#), "dataCorrupted", "Double optional/strict -1e400")
        XCTAssertEqual(thrown(TestNumberDoubleDefault.self,        #"{"v":-1e400}"#), nil, "Double default -1e400")
        XCTAssertEqual(thrown(TestNumberDoubleRequired.self,       #"{"v":"1e400"}"#), "typeMismatch", "Double required \"1e400\"")
        XCTAssertEqual(thrown(TestNumberDoubleOptional.self,       #"{"v":"1e400"}"#), nil, "Double optional \"1e400\"")
        XCTAssertEqual(thrown(TestNumberDoubleOptionalStrict.self, #"{"v":"1e400"}"#), "typeMismatch", "Double optional/strict \"1e400\"")
        XCTAssertEqual(thrown(TestNumberDoubleDefault.self,        #"{"v":"1e400"}"#), nil, "Double default \"1e400\"")
#if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
        // Float16, which Intel macOS and Intel Mac Catalyst do not have
        XCTAssertNil(thrown(TestNumberFloat16Required.self, #"{"v":1.5}"#), "Float16 required, 1.5")
        XCTAssertNil(thrown(TestNumberFloat16Required.self, #"{"v":65504}"#), "Float16 required, 65504")
        XCTAssertEqual(thrown(TestNumberFloat16Required.self,       #"{"v":100000}"#), "dataCorrupted", "Float16 required 100000")
        XCTAssertEqual(thrown(TestNumberFloat16Optional.self,       #"{"v":100000}"#), nil, "Float16 optional 100000")
        XCTAssertEqual(thrown(TestNumberFloat16OptionalStrict.self, #"{"v":100000}"#), "dataCorrupted", "Float16 optional/strict 100000")
        XCTAssertEqual(thrown(TestNumberFloat16Default.self,        #"{"v":100000}"#), nil, "Float16 default 100000")
        XCTAssertEqual(thrown(TestNumberFloat16Required.self,       #"{"v":70000}"#), "dataCorrupted", "Float16 required 70000")
        XCTAssertEqual(thrown(TestNumberFloat16Optional.self,       #"{"v":70000}"#), nil, "Float16 optional 70000")
        XCTAssertEqual(thrown(TestNumberFloat16OptionalStrict.self, #"{"v":70000}"#), "dataCorrupted", "Float16 optional/strict 70000")
        XCTAssertEqual(thrown(TestNumberFloat16Default.self,        #"{"v":70000}"#), nil, "Float16 default 70000")
        XCTAssertEqual(thrown(TestNumberFloat16Required.self,       #"{"v":"100000"}"#), "typeMismatch", "Float16 required \"100000\"")
        XCTAssertEqual(thrown(TestNumberFloat16Optional.self,       #"{"v":"100000"}"#), nil, "Float16 optional \"100000\"")
        XCTAssertEqual(thrown(TestNumberFloat16OptionalStrict.self, #"{"v":"100000"}"#), "typeMismatch", "Float16 optional/strict \"100000\"")
        XCTAssertEqual(thrown(TestNumberFloat16Default.self,        #"{"v":"100000"}"#), nil, "Float16 default \"100000\"")
#endif
        // Decimal
        XCTAssertNil(thrown(TestNumberDecimalRequired.self, #"{"v":1.5}"#), "Decimal required, 1.5")
        XCTAssertNil(thrown(TestNumberDecimalRequired.self, #"{"v":123456789.123}"#), "Decimal required, 123456789.123")
        XCTAssertEqual(thrown(TestNumberDecimalRequired.self,       #"{"v":1e400}"#), "dataCorrupted", "Decimal required 1e400")
        XCTAssertEqual(thrown(TestNumberDecimalOptional.self,       #"{"v":1e400}"#), nil, "Decimal optional 1e400")
        XCTAssertEqual(thrown(TestNumberDecimalOptionalStrict.self, #"{"v":1e400}"#), "dataCorrupted", "Decimal optional/strict 1e400")
        XCTAssertEqual(thrown(TestNumberDecimalDefault.self,        #"{"v":1e400}"#), nil, "Decimal default 1e400")
        XCTAssertEqual(thrown(TestNumberDecimalRequired.self,       #"{"v":"1e400"}"#), "typeMismatch", "Decimal required \"1e400\"")
        XCTAssertEqual(thrown(TestNumberDecimalOptional.self,       #"{"v":"1e400"}"#), nil, "Decimal optional \"1e400\"")
        XCTAssertEqual(thrown(TestNumberDecimalOptionalStrict.self, #"{"v":"1e400"}"#), "typeMismatch", "Decimal optional/strict \"1e400\"")
        XCTAssertEqual(thrown(TestNumberDecimalDefault.self,        #"{"v":"1e400"}"#), nil, "Decimal default \"1e400\"")
        
        // The value of `default` is what a number that does not fit turns into.
        XCTAssertEqual(try TestNumberInt8Default.decoded(from: Data(#"{"v":300}"#.utf8)).v, 1)
        XCTAssertEqual(try TestNumberInt8Default.decoded(from: Data(#"{"v":7}"#.utf8)).v, 7)
        XCTAssertEqual(try TestNumberInt8Optional.decoded(from: Data(#"{"v":7}"#.utf8)).v, 7)
        XCTAssertNil(try TestNumberInt8Optional.decoded(from: Data(#"{"v":300}"#.utf8)).v)
        
        // A wrong JSON type is still a `typeMismatch`.
        XCTAssertEqual(thrown(TestNumberInt8Required.self,       #"{"v":"x"}"#), "typeMismatch", "Int8 required not a number")
        XCTAssertEqual(thrown(TestNumberInt8OptionalStrict.self, #"{"v":[1]}"#), "typeMismatch", "Int8 optional/strict array")
        XCTAssertEqual(thrown(TestNumberDoubleRequired.self,     #"{"v":"x"}"#), "typeMismatch", "Double required not a number")
        XCTAssertEqual(thrown(TestNumberInt8Required.self,       #"{}"#), "keyNotFound", "Int8 required missing key")
        XCTAssertEqual(thrown(TestNumberInt8Required.self,       #"{"v":null}"#), "valueNotFound", "Int8 required null")
    }
    
    /// The layers of an optional, from the outside in: `.some(.some(.one))` is `["some", "some", "one"]`, `.some(nil)` is
    /// `["some", "none"]` and `nil` is `["none"]`. `== nil` and `XCTAssertNil` can not tell `.some(nil)` from `nil` for this purpose, and the
    /// difference is exactly what a wrong number of layers produces.
    private func layers<T>(of value: T) -> [String] {
        var result: [String] = []
        var current: Any = value
        // `value` is passed as `T`, not `Any?`, so the layers are not flattened on the way in
        while let optional = current as? any OptionalProtocolForTests {
            guard let next = optional.unwrappedForTests else { result.append("none"); return result }
            result.append("some")
            current = next
        }
        result.append("\(current)")
        return result
    }
    
    /// An optional of an optional reads the raw value of an enum the same way a single optional does: `"1"` is `.one`
    /// at every depth. The generated code asks the runtime for the type inside the optionals and wraps the result.
    func testEnumAtEveryOptionalDepth() throws {
        func decoded<T: Decodable>(_ type: T.Type, _ json: String) throws -> T { try T.decoded(from: Data(json.utf8)) }
        
        // the value, as a number and as a string
        for json in [#"{"v":1}"#, #"{"v":"1"}"#] {
            XCTAssertEqual(try decoded(TestEnumLayers0.self, json).v, .one, json)
            XCTAssertEqual(try decoded(TestEnumLayers1.self, json).v, .one, json)
            XCTAssertEqual((try decoded(TestEnumLayers2.self, json).v) ?? nil, .one, json)
            XCTAssertEqual(((try decoded(TestEnumLayers3.self, json).v) ?? nil) ?? nil, .one, json)
            XCTAssertEqual((try decoded(TestEnumLayers2Spelled.self, json).v) ?? nil, .one, json)
            XCTAssertEqual((try decoded(TestEnumLayers2Mixed.self, json).v) ?? nil, .one, json)
            XCTAssertEqual((try decoded(TestEnumLayers2Unwrapped.self, json).v) ?? nil, .one, json)
            // `Optional<...>!`: the `!` is outside the spelled-out optional, and it counts the same
            XCTAssertEqual(try decoded(TestEnumLayers1SpelledUnwrapped.self, json).v, .one, json)
            XCTAssertEqual((try decoded(TestEnumLayers2SpelledUnwrapped.self, json).v) ?? nil, .one, json)
            // deeper: `E???!` is four layers, and the `!` is the one on the outside
            XCTAssertEqual(layers(of: try decoded(TestEnumLayers3Unwrapped.self, json).v), ["some", "some", "some", "some", "one"], json)
            XCTAssertEqual(layers(of: try decoded(TestEnumLayers4Unwrapped.self, json).v), ["some", "some", "some", "some", "some", "one"], json)
        }
        
        // the outer layers are real: a value that is there is `.some`, not a flattened `nil`
        XCTAssertEqual(layers(of: try decoded(TestEnumLayers1.self, #"{"v":"1"}"#).v), ["some", "one"])
        XCTAssertEqual(layers(of: try decoded(TestEnumLayers2.self, #"{"v":"1"}"#).v), ["some", "some", "one"])
        XCTAssertEqual(layers(of: try decoded(TestEnumLayers3.self, #"{"v":"1"}"#).v), ["some", "some", "some", "one"])
        
        // absent, `null`, a value that is not a case, and a wrong JSON type: all give `nil` for an optional
        for json in ["{}", #"{"v":null}"#, #"{"v":9}"#, #"{"v":"x"}"#] {
            // the outermost layer is `none`: no value is not a value that is itself `nil`
            XCTAssertEqual(layers(of: try decoded(TestEnumLayers1.self, json).v), ["none"], json)
            XCTAssertEqual(layers(of: try decoded(TestEnumLayers2.self, json).v), ["none"], json)
            XCTAssertEqual(layers(of: try decoded(TestEnumLayers3.self, json).v), ["none"], json)
        }
        
        // `strictType` and `default` work at depth, as they do for one layer
        XCTAssertEqual(thrown(TestEnumLayers2Strict.self, #"{"v":"x"}"#), "typeMismatch")
        XCTAssertEqual(thrown(TestEnumLayers2Strict.self, #"{"v":9}"#), "dataCorrupted")
        XCTAssertNil(thrown(TestEnumLayers2Strict.self, #"{"v":null}"#))
        XCTAssertEqual((try decoded(TestEnumLayers2Default.self, "{}").v) ?? nil, .one)
        XCTAssertEqual((try decoded(TestEnumLayers2Default.self, #"{"v":9}"#).v) ?? nil, .one)
        XCTAssertEqual((try decoded(TestEnumLayers2Default.self, #"{"v":0}"#).v) ?? nil, .zero)
        
        // a nested key, and an enum whose raw value is a string
        XCTAssertEqual((try decoded(TestEnumLayers2Nested.self, #"{"a":{"b":"1"}}"#).v) ?? nil, .one)
        XCTAssertEqual(layers(of: try decoded(TestEnumLayers2Nested.self, #"{"a":{"b":9}}"#).v), ["none"])
        XCTAssertEqual((try decoded(TestStringEnumLayers2.self, #"{"v":"two"}"#).v) ?? nil, .two)
        XCTAssertEqual(layers(of: try decoded(TestStringEnumLayers2.self, #"{"v":"z"}"#).v), ["none"])
        
        // an `!` on the outside promises a value, whatever is under it.
        // This test owns the behaviour. It does not see the text the macro generates for it: with `optional: false`, `_decode` throws
        // for a missing key or a `null` before the generated `!` is reached, so a different spelling there changes nothing at runtime.
        // The text is checked in `ExCodableMacroTests.testOptionalLayersAreWrappedByTheGeneratedCode`.
        XCTAssertEqual(thrown(TestEnumLayers2Unwrapped.self, "{}"), "keyNotFound")
        XCTAssertEqual(thrown(TestEnumLayers2Unwrapped.self, #"{"v":null}"#), "valueNotFound")
        for type in [TestEnumLayers2Unwrapped.self, TestEnumLayers1SpelledUnwrapped.self, TestEnumLayers2SpelledUnwrapped.self,
                     TestEnumLayers3Unwrapped.self, TestEnumLayers4Unwrapped.self] as [any Decodable.Type] {
            XCTAssertEqual(thrown(type, "{}"), "keyNotFound", "\(type)")
            XCTAssertEqual(thrown(type, #"{"v":null}"#), "valueNotFound", "\(type)")
            XCTAssertEqual(thrown(type, #"{"v":9}"#), "dataCorrupted", "\(type)")
            XCTAssertEqual(thrown(type, #"{"v":"x"}"#), "typeMismatch", "\(type)")
        }
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

private protocol OptionalProtocolForTests {
    /// The wrapped value, or `nil` for `.none`. It is `Any?` on purpose: one layer at a time, never flattened.
    var unwrappedForTests: Any? { get }
}
extension Optional: OptionalProtocolForTests {
    var unwrappedForTests: Any? {
        switch self {
            case .some(let wrapped): return wrapped
            case .none: return nil
        }
    }
}
