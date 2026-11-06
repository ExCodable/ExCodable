//
//  ExCodableMacroTests.swift
//  ExCodable
//
//  Created by Míng on 2026-11-04.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import XCTest

// @testable
import ExCodable
import ExCodableMacros

final class ExCodableMacroTests: XCTestCase {
    
    private let macros: [String: Macro.Type] = [
        "ExCodable": ExCodableMacro.self,
        "ExCodableKey": ExCodableKeyMacro.self,
        "ExCodableExcept": ExCodableExceptMacro.self,
    ]
    
    /// `assertMacroExpansion` passes no `protocols` to the extension macro unless the spec declares them.
    private let conformingMacroSpecs: [String: MacroSpec] = [
        "ExCodable": MacroSpec(type: ExCodableMacro.self, conformances: ["Decodable", "Encodable"]),
        "ExCodableKey": MacroSpec(type: ExCodableKeyMacro.self),
        "ExCodableExcept": MacroSpec(type: ExCodableExceptMacro.self),
    ]
    
    /// Same reasoning for `strictType`: a strict type check is exactly the failure `default` exists
    /// to absorb.
    func testDefaultAndStrictTypeAreExclusive() {
        assertMacroExpansion(
            """
            @ExCodable
            struct S {
                @ExCodableKey("v", default: 1, strictType: true)
                var v: Int
            }
            """,
            expandedSource: """
            struct S {
                var v: Int
            }
            
            extension S {
                init(from decoder: Decoder) throws {
                    let exCodableTypeConverter = ExCodableRuntime._converter(of: Self.self)
                    self.`v` = try ExCodableRuntime._decode((Int).self, from: decoder, keys: ["v"], optional: true, strictType: true, converter: exCodableTypeConverter) ?? 1
                }
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime._encode(self.`v`, to: encoder, for: "v", optional: false, strictType: true)
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@ExCodableKey can not use a default value together with strictType",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }
    
    /// An explicit `false` means the `strictType` is off, so it composes with `default` without conflict.
    func testDefaultWithExplicitFalseIsAllowed() {
        assertMacroExpansion(
            """
            @ExCodable
            struct S {
                @ExCodableKey("v", default: 1, strictType: false)
                var v: Int
                init(`v`: Int) {
                    self.`v` = `v`
                }
            }
            """,
            expandedSource: """
            struct S {
                var v: Int
                init(`v`: Int) {
                    self.`v` = `v`
                }
            }
            
            extension S {
                init(from decoder: Decoder) throws {
                    let exCodableTypeConverter = ExCodableRuntime._converter(of: Self.self)
                    self.`v` = try ExCodableRuntime._decode((Int).self, from: decoder, keys: ["v"], optional: true, strictType: false, converter: exCodableTypeConverter) ?? 1
                }
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime._encode(self.`v`, to: encoder, for: "v", optional: false, strictType: false)
                }
            }
            """,
            diagnostics: [],
            macros: macros
        )
    }
    
    func testMainActorStructGetsIsolatedConformance() {
        assertMacroExpansion(
            """
            @MainActor
            @ExCodable
            struct S {
                @ExCodableKey
                var v: Int
                init(v: Int) {
                    self.v = v
                }
            }
            """,
            expandedSource: """
            @MainActor
            struct S {
                var v: Int
                init(v: Int) {
                    self.v = v
                }
            }
            
            extension S: @MainActor Decodable, @MainActor Encodable {
                init(from decoder: Decoder) throws {
                    let exCodableTypeConverter = ExCodableRuntime._converter(of: Self.self)
                    self.`v` = try ExCodableRuntime._decode((Int).self, from: decoder, keys: ["v"], optional: false, strictType: false, converter: exCodableTypeConverter)!
                }
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime._encode(self.`v`, to: encoder, for: "v", optional: false, strictType: false)
                }
            }
            """,
            diagnostics: [],
            macroSpecs: conformingMacroSpecs
        )
    }
    
    func testAttributedInheritedTypeIsNotSuperclass() {
        assertMacroExpansion(
            """
            @ExCodable
            final class C: @unchecked Sendable {
                @ExCodableKey
                var v: Int
            }
            """,
            expandedSource: """
            final class C: @unchecked Sendable {
                var v: Int
            
                required init(from decoder: Decoder) throws {
                    let exCodableTypeConverter = ExCodableRuntime._converter(of: Self.self)
                    self.`v` = try ExCodableRuntime._decode((Int).self, from: decoder, keys: ["v"], optional: false, strictType: false, converter: exCodableTypeConverter)!
                }
            
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime._encode(self.`v`, to: encoder, for: "v", optional: false, strictType: false)
                }
            }
            """,
            diagnostics: [],
            macros: macros
        )
    }

    // MARK: let with an initial value under .allKeys
    
    private let skippedLetMessage = "@ExCodable(.allKeys) does not code 'kind': a let with an initial value is a constant, and decoding can not assign it again. Mark it @ExCodableExcept to say that is intended, or declare it with var to code it."
    
    func testAllKeysWarnsAboutLetWithInitialValue() {
        assertMacroExpansion(
            """
            @ExCodable(.allKeys)
            struct S {
                var id: Int
                let kind = "user"
            }
            """,
            expandedSource: """
            struct S {
                var id: Int
                let kind = "user"
            
                init(`id`: Int) {
                    self.`id` = `id`
                }
            }
            
            extension S {
                init(from decoder: Decoder) throws {
                    let exCodableTypeConverter = ExCodableRuntime._converter(of: Self.self)
                    self.`id` = try ExCodableRuntime._decode((Int).self, from: decoder, keys: ["id"], optional: false, strictType: false, converter: exCodableTypeConverter)!
                }
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime._encode(self.`id`, to: encoder, for: "id", optional: false, strictType: false)
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: skippedLetMessage, line: 4, column: 9, severity: .warning)
            ],
            macros: macros
        )
    }
    
    /// The ways to answer the warning, and the cases that were never a problem. Each one expands without a diagnostic.
    func testNoWarningForLetWithInitialValueWhenItIsIntended() {
        let decode = """
            extension S {
                init(from decoder: Decoder) throws {
                    let exCodableTypeConverter = ExCodableRuntime._converter(of: Self.self)
                    self.`id` = try ExCodableRuntime._decode((Int).self, from: decoder, keys: ["id"], optional: false, strictType: false, converter: exCodableTypeConverter)!
                }
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime._encode(self.`id`, to: encoder, for: "id", optional: false, strictType: false)
                }
            }
            """
        
        // @ExCodableExcept says the constant is meant to stay out.
        assertMacroExpansion(
            """
            @ExCodable(.allKeys)
            struct S {
                var id: Int
                @ExCodableExcept let kind = "user"
            }
            """,
            expandedSource: """
            struct S {
                var id: Int
                let kind = "user"
            
                init(`id`: Int) {
                    self.`id` = `id`
                }
            }
            
            \(decode)
            """,
            diagnostics: [],
            macros: macros
        )
        
        // var is coded, so it is not a constant to explain.
        assertMacroExpansion(
            """
            @ExCodable(.allKeys)
            struct S {
                var id: Int
                static let kind = "user"
            }
            """,
            expandedSource: """
            struct S {
                var id: Int
                static let kind = "user"
            
                init(`id`: Int) {
                    self.`id` = `id`
                }
            }
            
            \(decode)
            """,
            diagnostics: [],
            macros: macros
        )
        
        // Only .allKeys has an implicit rule to explain. With .exCodableKeys the property is simply not marked.
        assertMacroExpansion(
            """
            @ExCodable
            struct S {
                @ExCodableKey var id: Int
                let kind = "user"
            }
            """,
            expandedSource: """
            struct S {
                var id: Int
                let kind = "user"
            
                init(`id`: Int) {
                    self.`id` = `id`
                }
            }
            
            \(decode)
            """,
            diagnostics: [],
            macros: macros
        )
    }
    
    /// Each skipped constant is reported once, by its own name.
    func testAllKeysWarnsOncePerSkippedLet() {
        assertMacroExpansion(
            """
            @ExCodable(.allKeys)
            struct S {
                var id: Int
                let a = 1
                let b = 2
            }
            """,
            expandedSource: """
            struct S {
                var id: Int
                let a = 1
                let b = 2
            
                init(`id`: Int) {
                    self.`id` = `id`
                }
            }
            
            extension S {
                init(from decoder: Decoder) throws {
                    let exCodableTypeConverter = ExCodableRuntime._converter(of: Self.self)
                    self.`id` = try ExCodableRuntime._decode((Int).self, from: decoder, keys: ["id"], optional: false, strictType: false, converter: exCodableTypeConverter)!
                }
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime._encode(self.`id`, to: encoder, for: "id", optional: false, strictType: false)
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: skippedLetMessage.replacingOccurrences(of: "'kind'", with: "'a'"), line: 4, column: 9, severity: .warning),
                DiagnosticSpec(message: skippedLetMessage.replacingOccurrences(of: "'kind'", with: "'b'"), line: 5, column: 9, severity: .warning),
            ],
            macros: macros
        )
    }
}
