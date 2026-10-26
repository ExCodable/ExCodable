//
//  ExCodableTests.swift
//  ExCodable
//
//  Created by Míng on 2021-02-10.
//  Copyright (c) 2021 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import XCTest

// @testable
import ExCodable

final class ExCodableTests: XCTestCase {
    
    func testAnything() {
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
        let data = Data(#"{"count":3,"name":"ada"}"#.utf8)
        let test = try TestStructWithObservers.decoded(from: data)
        XCTAssertEqual(test, TestStructWithObservers(count: 3, name: "ada"))
        let encoded = try test.encoded() as Data
        let copy = try TestStructWithObservers.decoded(from: encoded)
        XCTAssertEqual(copy, test)
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
            XCTAssertEqual(test, TestStructWithOptionals(bool: true,
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
                                                         string: "string"))
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
        let values = Data(#"{"int":418,"string":"I'm a teapot"}"#.utf8)
        let decoded = try TestDefault.decoded(from: values)
        XCTAssertEqual(decoded.int, 418)
        XCTAssertEqual(decoded.string, "I'm a teapot")
        
        let missing = Data(#"{}"#.utf8)
        let fallback = try TestDefault.decoded(from: missing)
        XCTAssertEqual(fallback.int, 0)
        XCTAssertEqual(fallback.string, "default")
        
        let nulls = Data(#"{"int":null,"string":null}"#.utf8)
        let nullFallback = try TestDefault.decoded(from: nulls)
        XCTAssertEqual(nullFallback.int, 0)
        XCTAssertEqual(nullFallback.string, "default")
        
        let data = try decoded.encoded() as Data
        let copy = try TestDefault.decoded(from: data)
        XCTAssertEqual(copy.int, decoded.int)
        XCTAssertEqual(copy.string, decoded.string)
    }
    
    func testNonnullAndThrows() throws {
        
        let noIntData = Data(#"""
        {
            "noInt": true
        }
        """#.utf8)
        XCTAssertThrowsError(try TestNonnull.decoded(from: noIntData)) { error in
            guard case DecodingError.keyNotFound = error else { return XCTFail("\(error)") }
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
            guard case DecodingError.keyNotFound = error else { return XCTFail("\(error)") }
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
        
        let absent = try TestThrows(throwsString: nil).encoded() as Data
        let absentJSON = try JSONSerialization.jsonObject(with: absent) as! [String: Any]
        XCTAssertTrue(absentJSON.isEmpty)
        
        let nestedAbsent = try TestNestedThrows(throwsString: nil).encoded() as Data
        let nestedAbsentJSON = try JSONSerialization.jsonObject(with: nestedAbsent) as! [String: Any]
        XCTAssertTrue(nestedAbsentJSON.isEmpty)
        
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
