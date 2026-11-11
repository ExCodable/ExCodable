//
//  ExCodableMacroTests.swift
//  ExCodable
//
//  Created by Míng on 2026-11-04.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import SwiftDiagnostics
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
    
    /// A default exists to absorb a failed decode, and `strictType` asks for it to be reported. With an error, nothing is generated.
    func testDefaultAndStrictTypeGenerateNothing() {
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
            """,
            diagnostics: [DiagnosticSpec(id: MessageID(domain: "ExCodable", id: "defaultWithStrictType"), message: messageOfFirstDiagnostic(in: "@ExCodable\nstruct S {\n    @ExCodableKey(\"v\", default: 1, strictType: true)\n    var v: Int\n}"), line: 3, column: 5)],
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

    // MARK: errors and warnings
    //
    // A problem is checked by its kind, severity and position. The wording is free to change: nothing here repeats it.
    
    private struct Expected {
        var kind: String
        var line: Int
        var column: Int
        var severity: DiagnosticSeverity = .error
    }
    
    /// Runs the member role of the macro on the first type in `source`. That is the only role that reports a problem,
    /// so each one comes back exactly once.
    private func raised(by source: String) -> [Diagnostic] {
        let context = BasicMacroExpansionContext(sourceFiles: [:])
        for statement in Parser.parse(source: source).statements {
            guard let declaration = statement.item.asProtocol(DeclGroupSyntax.self),
                  let attribute = declaration.attributes.first?.as(AttributeSyntax.self) else { continue }
            _ = try? ExCodableMacro.expansion(of: attribute, providingMembersOf: declaration, conformingTo: [], in: context)
            break
        }
        return context.diagnostics
    }
    
    /// A property-level attribute is a peer macro. It reports its own problems, and `member` is the owner's report.
    private func raisedByPeer<M: PeerMacro>(_ macro: M.Type, source: String) -> [Diagnostic] {
        let context = BasicMacroExpansionContext(sourceFiles: [:])
        let tree = Parser.parse(source: source)
        for statement in tree.statements {
            guard let type = statement.item.asProtocol(DeclGroupSyntax.self) else { continue }
            for member in type.memberBlock.members {
                guard let attribute = member.decl.asProtocol(WithAttributesSyntax.self)?.attributes.first?.as(AttributeSyntax.self) else { continue }
                _ = try? macro.expansion(of: attribute, providingPeersOf: member.decl, in: context)
            }
        }
        return context.diagnostics
    }
    
    /// `assertMacroExpansion` insists on a message. Reading it from the macro keeps its wording out of the tests.
    private func messageOfFirstDiagnostic(in source: String) -> String {
        raised(by: source).first?.message ?? "<no diagnostic>"
    }
    
    private func position(of diagnostic: Diagnostic) -> (line: Int, column: Int) {
        let location = diagnostic.location(converter: SourceLocationConverter(fileName: "test.swift", tree: diagnostic.node.root))
        return (location.line, location.column)
    }
    
    private func assertDiagnostics(_ found: [Diagnostic], _ expected: [Expected], file: StaticString = #filePath, line: UInt = #line) {
        guard found.count == expected.count else {
            return XCTFail("expected \(expected.count) diagnostics, got \(found.count): \(found.map(\.message))", file: file, line: line)
        }
        for (diagnostic, want) in zip(found, expected) {
            XCTAssertTrue(diagnostic.diagMessage.diagnosticID == MessageID(domain: "ExCodable", id: want.kind),
                          "expected '\(want.kind)', got: \(diagnostic.message)", file: file, line: line)
            XCTAssertEqual(diagnostic.diagMessage.severity, want.severity, "severity of '\(want.kind)'", file: file, line: line)
            let at = position(of: diagnostic)
            XCTAssertEqual(at.line, want.line, "line of '\(want.kind)'", file: file, line: line)
            XCTAssertEqual(at.column, want.column, "column of '\(want.kind)'", file: file, line: line)
        }
    }
    
    func testKeyOnComputedProperty() {
        assertDiagnostics(raised(by: """
            @ExCodable
            struct S {
                @ExCodableKey var a: Int
                @ExCodableKey var computed: Int { 1 }
            }
            """), [Expected(kind: "keyOnNonStoredProperty", line: 4, column: 23)])
    }
    
    func testKeyOnTuplePattern() {
        assertDiagnostics(raised(by: """
            @ExCodable
            struct S {
                @ExCodableKey var (a, b): (Int, Int)
            }
            """), [Expected(kind: "keyOnPatternProperty", line: 3, column: 23)])
    }
    
    func testAllKeysOnComputedProperty() {
        assertDiagnostics(raised(by: """
            @ExCodable(.allKeys)
            struct S {
                var id: Int
                var computed: Int { 1 }
            }
            """), [Expected(kind: "allKeysNonStoredProperty", line: 4, column: 9)])
        // @ExCodableExcept is the way out.
        assertDiagnostics(raised(by: """
            @ExCodable(.allKeys)
            struct S {
                var id: Int
                @ExCodableExcept var computed: Int { 1 }
            }
            """), [])
    }
    
    func testAllKeysOnTuplePattern() {
        assertDiagnostics(raised(by: """
            @ExCodable(.allKeys)
            struct S {
                var (a, b): (Int, Int) = (1, 2)
            }
            """), [Expected(kind: "allKeysPatternProperty", line: 3, column: 9)])
    }
    
    func testKeyOnLetWithValue() {
        assertDiagnostics(raised(by: """
            @ExCodable
            struct S {
                @ExCodableKey let x = 1
            }
            """), [Expected(kind: "keyOnLetWithValue", line: 3, column: 23)])
    }
    
    func testMissingTypeAndValue() {
        assertDiagnostics(raised(by: """
            @ExCodable
            struct S {
                @ExCodableKey var x
            }
            """), [Expected(kind: "missingTypeAndValue", line: 3, column: 23)])
    }
    
    func testDefaultTogetherWithStrictType() {
        // `default:` in the attribute, and an initial value on the property: both are a default.
        assertDiagnostics(raised(by: """
            @ExCodable
            struct S {
                @ExCodableKey(default: 1, strictType: true) var a: Int
                @ExCodableKey(strictType: true) var b: Int = 2
            }
            """), [Expected(kind: "defaultWithStrictType", line: 3, column: 5),
                   Expected(kind: "defaultWithStrictType", line: 4, column: 5)])
        // `strictType: false` is not a contradiction.
        assertDiagnostics(raised(by: """
            @ExCodable
            struct S {
                @ExCodableKey(default: 1, strictType: false) var a: Int
            }
            """), [])
    }
    
    /// Several problems in one type are all reported in the same pass, each on its own declaration.
    func testSeveralProblemsAreReportedTogether() {
        assertDiagnostics(raised(by: """
            @ExCodable
            struct S {
                @ExCodableKey(default: 1, strictType: true) var a: Int
                @ExCodableKey var b: Int { 1 }
                @ExCodableKey let c = 1
            }
            """), [Expected(kind: "defaultWithStrictType", line: 3, column: 5),
                   Expected(kind: "keyOnNonStoredProperty", line: 4, column: 23),
                   Expected(kind: "keyOnLetWithValue", line: 5, column: 23)])
    }
    
    func testKeyWrittenTwice() {
        assertDiagnostics(raised(by: """
            @ExCodable
            struct S {
                @ExCodableKey @ExCodableKey var x: Int
            }
            """), [Expected(kind: "duplicateKey", line: 3, column: 19)])
    }
    
    func testExCodableOnATypeThatIsNotAStructOrClass() {
        assertDiagnostics(raised(by: "@ExCodable\nenum E { case a }"), [Expected(kind: "notStructOrClass", line: 1, column: 1)])
        assertDiagnostics(raised(by: "@ExCodable\nactor A { var x = 0 }"), [Expected(kind: "notStructOrClass", line: 1, column: 1)])
    }
    
    func testOptionThatIsNotALiteral() {
        assertDiagnostics(raised(by: "@ExCodable(options)\nstruct S { var x: Int }"), [Expected(kind: "optionNotLiteral", line: 1, column: 12)])
        // Written out, both options are fine.
        assertDiagnostics(raised(by: "@ExCodable(.allKeys)\nstruct S { var x: Int }"), [])
        assertDiagnostics(raised(by: "@ExCodable(.exCodableKeys)\nstruct S { @ExCodableKey var x: Int }"), [])
    }
    
    func testGenericTypeThatDeclaresCodable() {
        assertDiagnostics(raised(by: """
            @ExCodable
            struct S<T>: Codable {
                @ExCodableKey var x: Int
            }
            """), [Expected(kind: "genericNotCodable", line: 1, column: 1)])
    }
    
    // MARK: warnings
    
    func testAllKeysWarnsAboutLetWithInitialValue() {
        assertDiagnostics(raised(by: """
            @ExCodable(.allKeys)
            struct S {
                var id: Int
                let kind = "user"
                let version = 2
            }
            """), [Expected(kind: "letWithValueSkipped", line: 4, column: 9, severity: .warning),
                   Expected(kind: "letWithValueSkipped", line: 5, column: 9, severity: .warning)])
    }
    
    /// The ways to answer that warning, and the cases that were never a problem.
    func testNoWarningForLetWithInitialValueWhenItIsIntended() {
        // @ExCodableExcept says the constant is meant to stay out.
        assertDiagnostics(raised(by: "@ExCodable(.allKeys)\nstruct S {\n    var id: Int\n    @ExCodableExcept let kind = \"user\"\n}"), [])
        // var is coded, and a let without a value is coded.
        assertDiagnostics(raised(by: "@ExCodable(.allKeys)\nstruct S {\n    var id: Int\n    var kind = \"user\"\n    let note: String\n}"), [])
        // static is not a stored property of the instance.
        assertDiagnostics(raised(by: "@ExCodable(.allKeys)\nstruct S {\n    var id: Int\n    static let kind = \"user\"\n}"), [])
        // Only .allKeys has an implicit rule to explain. With .exCodableKeys the property is simply not marked.
        assertDiagnostics(raised(by: "@ExCodable\nstruct S {\n    @ExCodableKey var id: Int\n    let kind = \"user\"\n}"), [])
    }
    
    func testKeyOnStaticPropertyIsAWarning() {
        assertDiagnostics(raisedByPeer(ExCodableKeyMacro.self, source: """
            struct S {
                @ExCodableKey static var shared: Int = 1
            }
            """), [Expected(kind: "keyOnStaticProperty", line: 2, column: 5, severity: .warning)])
    }
    
    func testAttributeOutsideAnExCodableTypeIsAWarning() {
        assertDiagnostics(raisedByPeer(ExCodableKeyMacro.self, source: "struct S {\n    @ExCodableKey var x: Int\n}"),
                          [Expected(kind: "keyWithoutExCodable", line: 2, column: 5, severity: .warning)])
        assertDiagnostics(raisedByPeer(ExCodableExceptMacro.self, source: "struct S {\n    @ExCodableExcept var x: Int\n}"),
                          [Expected(kind: "exceptWithoutExCodable", line: 2, column: 5, severity: .warning)])
    }
    
    // MARK: errors on the property attributes
    
    func testAttributesOnSomethingThatIsNotAVariable() {
        assertDiagnostics(raisedByPeer(ExCodableKeyMacro.self, source: "struct S {\n    @ExCodableKey func f() {}\n}"),
                          [Expected(kind: "keyOnNonVariable", line: 2, column: 5)])
        assertDiagnostics(raisedByPeer(ExCodableExceptMacro.self, source: "struct S {\n    @ExCodableExcept func f() {}\n}"),
                          [Expected(kind: "exceptOnNonVariable", line: 2, column: 5)])
    }
    
    func testExceptTogetherWithKey() {
        assertDiagnostics(raisedByPeer(ExCodableExceptMacro.self, source: "struct S {\n    @ExCodableExcept @ExCodableKey var x: Int\n}"),
                          [Expected(kind: "exceptWithKey", line: 2, column: 5)])
    }
    
    // MARK: what is generated after a problem
    
    /// Nothing is generated when there is an error: the compiler would only add errors about the members that are missing.
    func testNothingIsGeneratedAfterAnError() {
        assertMacroExpansion(
            """
            @ExCodable
            struct S {
                @ExCodableKey var a: Int
                @ExCodableKey var b: Int { 1 }
            }
            """,
            expandedSource: """
            struct S {
                var a: Int
                var b: Int { 1 }
            }
            """,
            diagnostics: [DiagnosticSpec(id: MessageID(domain: "ExCodable", id: "keyOnNonStoredProperty"), message: messageOfFirstDiagnostic(in: "@ExCodable\nstruct S {\n    @ExCodableKey var a: Int\n    @ExCodableKey var b: Int { 1 }\n}"), line: 4, column: 23)],
            macros: macros
        )
    }

    
    // MARK: layers of optionals
    
    /// The runtime decodes the type inside the optionals once. The generated code wraps the result in the rest of the layers,
    /// so a raw value can be read at any depth, and the runtime needs no overload per depth.
    func testOptionalLayersAreWrappedByTheGeneratedCode() {
        func decodeLine(of type: String) -> String {
            let context = BasicMacroExpansionContext(sourceFiles: [:])
            for statement in Parser.parse(source: "@ExCodable\nstruct S {\n    @ExCodableKey var v: \(type)\n}").statements {
                guard let declaration = statement.item.as(StructDeclSyntax.self),
                      let attribute = declaration.attributes.first?.as(AttributeSyntax.self),
                      let extensions = try? ExCodableMacro.expansion(of: attribute, attachedTo: declaration, providingExtensionsOf: TypeSyntax(stringLiteral: "S"),
                                                                     conformingTo: [TypeSyntax(stringLiteral: "Decodable")], in: context) else { continue }
                let source = extensions.map(\.description).joined(separator: "\n")
                return source.split(separator: "\n").first { $0.contains("_decode(") }.map { String($0.drop { $0 == " " }) } ?? "<none>"
            }
            return "<no extension>"
        }
        let prefix = "self.`v` = try ExCodableRuntime._decode((E).self, from: decoder, keys: [\"v\"]"
        // 0 layers, and a `!` that only promises a value: required, unwrapped with `!`
        XCTAssertTrue(decodeLine(of: "E").hasPrefix(prefix + ", optional: false"))
        XCTAssertTrue(decodeLine(of: "E").hasSuffix(")!"))
        XCTAssertTrue(decodeLine(of: "E!").hasPrefix(prefix + ", optional: false"))
        // 1 layer: the runtime's own result
        XCTAssertTrue(decodeLine(of: "E?").hasPrefix(prefix + ", optional: true"))
        XCTAssertTrue(decodeLine(of: "E?").hasSuffix("exCodableTypeConverter)"))
        // every spelling of N layers asks for the same type and wraps it N - 1 times
        for spelling in ["E??", "Optional<E?>", "Optional<Optional<E>>", "(E?)?"] {
            XCTAssertTrue(decodeLine(of: spelling).hasPrefix(prefix), spelling)
            XCTAssertTrue(decodeLine(of: spelling).hasSuffix("exCodableTypeConverter).map(Optional.some)"), spelling)
        }
        for spelling in ["E???", "Optional<E??>", "((E?)?)?"] {
            XCTAssertTrue(decodeLine(of: spelling).hasSuffix("exCodableTypeConverter).map(Optional.some).map(Optional.some)"), spelling)
        }
        // an outermost `!` promises a value, whatever is under it: the property is required, so it is unwrapped like a plain type.
        // This test owns the generated text: `optional: false` and the trailing `)!`. What the property does at runtime when the value
        // is missing is checked in `FeatureTests.testEnumAtEveryOptionalDepth`, because `_decode` throws before the `!` is reached.
        for spelling in ["E!", "E?!", "E??!", "E???!", "E????!", "Optional<E>!", "Optional<E?>!", "Optional<E??>!", "(E?)!"] {
            XCTAssertTrue(decodeLine(of: spelling).hasPrefix(prefix + ", optional: false"), spelling)
            XCTAssertTrue(decodeLine(of: spelling).hasSuffix(")!"), spelling)
        }
        // only the optionals around the type are peeled: an optional inside a collection belongs to the type
        XCTAssertTrue(decodeLine(of: "[E?]?").hasPrefix("self.`v` = try ExCodableRuntime._decode(([E?]).self"))
        XCTAssertTrue(decodeLine(of: "[E]??").hasPrefix("self.`v` = try ExCodableRuntime._decode(([E]).self"))
    }
}
