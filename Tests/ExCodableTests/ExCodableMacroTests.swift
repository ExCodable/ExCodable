//
//  ExCodableMacroTests.swift
//  ExCodable
//
//  Created by Míng on 2026-11-04.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import SwiftSyntax
import SwiftSyntaxMacros
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
    
    /// `default` and `nonnull` cannot coexist: a default absorbs a failed decode, while `nonnull`
    /// insists the value is present. One of the two would be unreachable.
    func testDefaultAndNonnullAreExclusive() {
        assertMacroExpansion(
            """
            @ExCodable
            struct S {
                @ExCodableKey("v", default: 1, nonnull: true)
                var v: Int
            }
            """,
            expandedSource: """
            struct S {
                var v: Int
            }

            extension S {
                init(from decoder: Decoder) throws {
                    let exCodableTypeConverter = ExCodableRuntime.converter(of: Self.self)
                    if let exCodableValue = try ExCodableRuntime.decode((Int).self, from: decoder, keys: ["v"], nonnull: true, strictType: false, converter: exCodableTypeConverter) {
                        self.`v` = exCodableValue
                    }
                    else {
                        self.`v` = 1
                    }
                }
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime.encode(self.`v`, to: encoder, for: "v", nonnull: true, strictType: false)
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@ExCodableKey cannot use default together with nonnull or strictType",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }
    
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
                    let exCodableTypeConverter = ExCodableRuntime.converter(of: Self.self)
                    if let exCodableValue = try ExCodableRuntime.decode((Int).self, from: decoder, keys: ["v"], nonnull: false, strictType: true, converter: exCodableTypeConverter) {
                        self.`v` = exCodableValue
                    }
                    else {
                        self.`v` = 1
                    }
                }
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime.encode(self.`v`, to: encoder, for: "v", nonnull: false, strictType: true)
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@ExCodableKey cannot use default together with nonnull or strictType",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }
    
    /// An explicit `false` means the option is off, so it composes with `default` without conflict.
    func testDefaultWithExplicitFalseIsAllowed() {
        assertMacroExpansion(
            """
            @ExCodable
            struct S {
                @ExCodableKey("v", default: 1, nonnull: false, strictType: false)
                var v: Int
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
                    let exCodableTypeConverter = ExCodableRuntime.converter(of: Self.self)
                    if let exCodableValue = try ExCodableRuntime.decode((Int).self, from: decoder, keys: ["v"], nonnull: false, strictType: false, converter: exCodableTypeConverter) {
                        self.`v` = exCodableValue
                    }
                    else {
                        self.`v` = 1
                    }
                }
                func encode(to encoder: Encoder) throws {
                    try ExCodableRuntime.encode(self.`v`, to: encoder, for: "v", nonnull: false, strictType: false)
                }
            }
            """,
            diagnostics: [],
            macros: macros
        )
    }
}
