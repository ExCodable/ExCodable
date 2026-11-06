//
//  ExCodableMacro.swift
//  ExCodable
//
//  Created by Míng on 2026-10-22.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftCompilerPlugin

@main
struct ExCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ExCodableMacro.self,
        ExCodableKeyMacro.self,
        ExCodableExceptMacro.self,
    ]
}

public struct ExCodableMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try ExCodableExpansion.members(of: declaration, attribute: node, in: context)
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try ExCodableExpansion.extensions(of: declaration, type: type, protocols: protocols, attribute: node)
    }
}

public struct ExCodableKeyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: ExCodableDiagnostic.keyOnNonVariable))
            return []
        }
        if isStatic(variable) {
            for name in names(of: variable) {
                context.diagnose(Diagnostic(node: Syntax(node), message: ExCodableDiagnostic.keyOnStaticProperty(name)))
            }
            return []
        }
        if enclosingTypeIsNotExCodable(in: context) {
            context.diagnose(Diagnostic(node: Syntax(node), message: ExCodableDiagnostic.keyWithoutExCodable))
        }
        return []
    }
}

public struct ExCodableExceptMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: ExCodableDiagnostic.exceptOnNonVariable))
            return []
        }
        if hasAttribute(variable, named: "ExCodableKey") {
            context.diagnose(Diagnostic(node: Syntax(node), message: ExCodableDiagnostic.exceptWithKey))
            return []
        }
        if enclosingTypeIsNotExCodable(in: context) {
            context.diagnose(Diagnostic(node: Syntax(node), message: ExCodableDiagnostic.exceptWithoutExCodable))
        }
        return []
    }
}

// `nil` when the argument is not a literal member such as `.allKeys`. Only the member role reports that, once.
private func isAllKeys(_ attribute: AttributeSyntax, report context: (any MacroExpansionContext)? = nil) -> Bool? {
    guard let arguments = attribute.arguments,
          case let .argumentList(list) = arguments,
          let expression = list.first?.expression else { return false }
    guard let member = expression.as(MemberAccessExprSyntax.self) else {
        context?.diagnose(Diagnostic(node: Syntax(expression), message: ExCodableDiagnostic.optionNotLiteral(expression.trimmedDescription)))
        return nil
    }
    return member.declName.baseName.text == "allKeys"
}

// `ExCodable.ExCodable` -> `ExCodable`
private func attributeName(_ attribute: AttributeSyntax) -> String {
    let name = attribute.attributeName.trimmedDescription
    return name.split(separator: ".").last.map(String.init) ?? name
}

private func isStatic(_ variable: VariableDeclSyntax) -> Bool {
    let modifiers = variable.modifiers.map(\.name.text)
    return modifiers.contains("static") || modifiers.contains("class")
}

private func names(of variable: VariableDeclSyntax) -> [String] {
    variable.bindings.compactMap { $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text }
}

private func hasAttribute(_ variable: VariableDeclSyntax, named target: String) -> Bool {
    variable.attributes.contains { element in
        element.as(AttributeSyntax.self).map { attributeName($0) == target } ?? false
    }
}

private func enclosingTypeIsNotExCodable(in context: some MacroExpansionContext) -> Bool {
    for item in context.lexicalContext.reversed() {
        guard let decl = item.asProtocol(DeclGroupSyntax.self) else { continue }
        if decl.attributes.contains(where: { $0.as(AttributeSyntax.self).map({ attributeName($0) == "ExCodable" }) ?? false }) {
            return false
        }
    }
    return true
}

// Every message the macros report. One case per problem, so a message, its severity and its id live in one place.
enum ExCodableDiagnostic: DiagnosticMessage {
    // errors
    case keyOnNonStoredProperty
    case keyOnPatternProperty
    case exceptOnNonVariable
    case keyOnNonVariable
    case exceptWithKey
    case duplicateKey
    case allKeysNonStoredProperty(String)
    case allKeysPatternProperty
    case keyOnLetWithValue(String)
    case missingTypeAndValue(String)
    case defaultWithStrictType
    case optionNotLiteral(String)
    case notStructOrClass
    case genericNotCodable(String)
    // warnings
    case keyWithoutExCodable
    case exceptWithoutExCodable
    case letWithValueSkipped(String)
    case keyOnStaticProperty(String)
    
    // The text is `<who>: <what is wrong>. <what to do>`. Code in a message is quoted with single quotes, as the compiler does.
    var message: String {
        switch self {
            case .keyOnNonStoredProperty:
                "@ExCodableKey: needs a stored property to decode into, and this one is computed."
            case .keyOnPatternProperty:
                "@ExCodableKey: needs a named property. Declare each one in its own 'var' or 'let'."
            case .keyOnNonVariable:
                "@ExCodableKey: can only be applied to a stored property."
            case .exceptOnNonVariable:
                "@ExCodableExcept: can only be applied to a stored property."
            case .exceptWithKey:
                "@ExCodableExcept: can not be combined with '@ExCodableKey'. Remove one of them."
            case .duplicateKey:
                "@ExCodableKey: this property has it twice. Remove one."
            case let .allKeysNonStoredProperty(name):
                "@ExCodable: '\(name)' is computed, so '.allKeys' can not code it. Add '@ExCodableExcept' to leave it out."
            case .allKeysPatternProperty:
                "@ExCodable: '.allKeys' needs a named property. Declare each one in its own 'var' or 'let', or add '@ExCodableExcept' to leave it out."
            case let .keyOnLetWithValue(name):
                "@ExCodableKey: '\(name)' is a 'let' with an initial value, so decoding can not assign it. Remove the value, or declare it with 'var'."
            case let .missingTypeAndValue(name):
                "@ExCodableKey: '\(name)' needs a type or an initial value, so that the macro knows what to decode."
            case .defaultWithStrictType:
                "@ExCodableKey: 'default' and 'strictType' contradict each other. The default replaces a failed decode, and 'strictType' reports it. Remove one."
            case let .optionNotLiteral(text):
                "@ExCodable: can not evaluate '\(text)' at compile time. Write '.allKeys' or '.exCodableKeys' directly."
            case .notStructOrClass:
                "@ExCodable: can only be applied to a struct or a class."
            case let .genericNotCodable(list):
                "@ExCodable: '\(list)' must conform to 'Codable'. The type already declares 'Codable', 'Decodable' or 'Encodable', so the macro can not add the condition for you."
            case .keyWithoutExCodable:
                "@ExCodableKey: the enclosing type is not marked '@ExCodable', so this does nothing. Add '@ExCodable' to the type, or remove '@ExCodableKey'."
            case .exceptWithoutExCodable:
                "@ExCodableExcept: it only applies to a type marked '@ExCodable(.allKeys)', so this does nothing. Add that to the type, or remove '@ExCodableExcept'."
            case let .letWithValueSkipped(name):
                "@ExCodable: '.allKeys' does not code '\(name)', because it is a 'let' with an initial value. Mark it '@ExCodableExcept' if that is intended, or declare it with 'var' to code it."
            case let .keyOnStaticProperty(name):
                "@ExCodableKey: '\(name)' is a static property. It belongs to the type, not to an instance, so this does nothing. Remove it."
        }
    }
    
    var diagnosticID: MessageID {
        let id = switch self {
            case .keyOnNonStoredProperty: "keyOnNonStoredProperty"
            case .keyOnPatternProperty: "keyOnPatternProperty"
            case .exceptOnNonVariable: "exceptOnNonVariable"
            case .keyOnNonVariable: "keyOnNonVariable"
            case .exceptWithKey: "exceptWithKey"
            case .duplicateKey: "duplicateKey"
            case .allKeysNonStoredProperty: "allKeysNonStoredProperty"
            case .allKeysPatternProperty: "allKeysPatternProperty"
            case .keyOnLetWithValue: "keyOnLetWithValue"
            case .missingTypeAndValue: "missingTypeAndValue"
            case .defaultWithStrictType: "defaultWithStrictType"
            case .optionNotLiteral: "optionNotLiteral"
            case .notStructOrClass: "notStructOrClass"
            case .genericNotCodable: "genericNotCodable"
            case .keyWithoutExCodable: "keyWithoutExCodable"
            case .exceptWithoutExCodable: "exceptWithoutExCodable"
            case .letWithValueSkipped: "letWithValueSkipped"
            case .keyOnStaticProperty: "keyOnStaticProperty"
        }
        return MessageID(domain: "ExCodable", id: id)
    }
    
    var severity: DiagnosticSeverity {
        switch self {
            case .keyWithoutExCodable, .exceptWithoutExCodable, .letWithValueSkipped, .keyOnStaticProperty: .warning
            default: .error
        }
    }
}

private struct Problems {
    var context: (any MacroExpansionContext)?
    private(set) var hasError = false
    
    init(context: (any MacroExpansionContext)?) {
        self.context = context
    }
    
    mutating func report(_ message: ExCodableDiagnostic, at node: some SyntaxProtocol) {
        if message.severity == .error {
            hasError = true
        }
        context?.diagnose(Diagnostic(node: Syntax(node), message: message))
    }
}

private enum ExCodableExpansion {
    
    private enum Access: Int {
        case `private` = 0
        case `fileprivate` = 1
        case `internal` = 2
        case `package` = 3
        case `public` = 4
        
        var prefix: String {
            return switch self {
                case .private: "private "
                case .fileprivate: "fileprivate "
                case .internal: ""
                case .package: "package "
                case .public: "public "
            }
        }
        // Swift never synthesizes a `public` or `package` memberwise initializer, so those stay
        // unmarked rather than being widened or narrowed.
        var memberwisePrefix: String {
            return switch self {
                case .private, .fileprivate: prefix
                default: ""
            }
        }
    }
    
    private enum Kind { case `struct`, `class` }
    
    private struct Property {
        var access: Access
        // `false` for a `private` or `fileprivate` variable that already has a default.
        // Swift leaves those out of the memberwise initializer.
        var memberwise: Bool
        var name: String
        var type: String?
        var `default`: String?
        var codable: CodableSpec?
        var witness: String?
        // `.allKeys` codes an unmarked property exactly like an empty `@ExCodableKey`.
        static let implicitSpec = CodableSpec(keys: [], default: nil, strictType: "false", encode: nil, decode: nil)
    }
    
    private struct CodableSpec {
        var keys: [String]
        var `default`: String?
        var strictType: String
        var encode, decode: String?
    }
    
    // `@ExCodable` expands twice: as a member macro and as an extension macro. Everything is reported from here, once, and
    // `extensions` only reads the result. A problem is reported on the declaration it belongs to, and all of them in one
    // pass, so fixing one does not reveal the next.
    static func members(of declaration: some DeclGroupSyntax, attribute: AttributeSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: Syntax(attribute), message: ExCodableDiagnostic.notStructOrClass))
            return []
        }
        var problems = Problems(context: context)
        guard let allKeys = isAllKeys(attribute, report: context) else { return [] }
        if allKeys {
            warnAboutSkippedLets(in: declaration, context: context)
        }
        _ = genericCodableWhere(of: declaration, at: attribute, into: &problems)
        let properties = properties(of: declaration, allKeys: allKeys, into: &problems)
        // With an error reported, nothing is generated: the compiler would only add errors about missing members.
        guard !problems.hasError else { return [] }
        
        var decls: [DeclSyntax] = []
        if let defaults = defaultsEnum(for: properties) {
            decls.append(DeclSyntax(stringLiteral: defaults))
        }
        if declaration.is(StructDeclSyntax.self), !hasInitializer(declaration) {
            decls.append(DeclSyntax(stringLiteral: memberwiseInit(for: properties, typeAccess: accessLevel(of: declaration.modifiers))))
        }
        if declaration.is(ClassDeclSyntax.self) {
            let superclass = hasSuperclass(declaration)
            let access = accessLevel(of: declaration.modifiers).prefix
            var ignored = Problems(context: nil)
            let genericWhere = genericCodableWhere(of: declaration, at: attribute, into: &ignored)
            decls.append(DeclSyntax(stringLiteral: decodeInit(for: properties, kind: .class, hasSuperclass: superclass, access: access, genericWhere: genericWhere)))
            decls.append(DeclSyntax(stringLiteral: encodeFunction(for: properties, kind: .class, hasSuperclass: superclass, access: access, genericWhere: genericWhere)))
        }
        return decls
    }
    
    static func extensions(
        of declaration: some DeclGroupSyntax,
        type: some TypeSyntaxProtocol,
        protocols: [TypeSyntax],
        attribute: AttributeSyntax
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            // `@ExCodable` on an enum, an actor or a protocol: the member role has reported it.
            return []
        }
        var problems = Problems(context: nil)
        guard let allKeys = isAllKeys(attribute) else { return [] }
        let genericWhere = genericCodableWhere(of: declaration, at: attribute, into: &problems)
        // On a `@MainActor` type the generated members are main actor-isolated, so the conformance must be too.
        // Without it the compiler rejects the conformance as crossing into main actor-isolated code.
        let isolation = isMainActor(declaration) ? "@MainActor " : ""
        let names = protocols.map { isolation + $0.trimmedDescription }
        if declaration.is(ClassDeclSyntax.self) {
            guard !protocols.isEmpty else { return [] }
            return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: "extension \(type.trimmedDescription): \(names.joined(separator: ", "))\(genericWhere) {}"))]
        }
        let properties = properties(of: declaration, allKeys: allKeys, into: &problems)
        // The member role has reported the problem. Generating anything here would only add follow-on errors.
        guard !problems.hasError else { return [] }
        let access = accessLevel(of: declaration.modifiers).prefix
        let conformance = names.isEmpty ? "" : ": " + names.joined(separator: ", ")
        let source = """
        extension \(type.trimmedDescription)\(conformance)\(genericWhere) {
        \(decodeInit(for: properties, kind: .struct, hasSuperclass: false, access: access))
        \(encodeFunction(for: properties, kind: .struct, hasSuperclass: false, access: access))
        }
        """
        return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: source))]
    }
    
    // A `let` with an initial value is a constant. `.allKeys` leaves it out of coding, because decoding would have to assign
    // it a second time, and that is not allowed. Without a hint it looks as if the property were coded.
    private static func warnAboutSkippedLets(in declaration: some DeclGroupSyntax, context: some MacroExpansionContext) {
        for item in declaration.memberBlock.members {
            guard let variable = item.decl.as(VariableDeclSyntax.self),
                  variable.bindingSpecifier.tokenKind == .keyword(.let) else { continue }
            let modifiers = variable.modifiers.map(\.name.text)
            if modifiers.contains("static") || modifiers.contains("class") { continue }
            // Already decided by the user: `@ExCodableExcept` is the answer this warning asks for, and `@ExCodableKey` is an error.
            if hasAttribute(variable, named: "ExCodableExcept") || hasAttribute(variable, named: "ExCodableKey") { continue }
            for binding in variable.bindings where binding.initializer != nil {
                guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }
                context.diagnose(Diagnostic(node: Syntax(binding.pattern), message: ExCodableDiagnostic.letWithValueSkipped(name)))
            }
        }
    }
    
    private static func properties(of declaration: some DeclGroupSyntax, allKeys: Bool, into problems: inout Problems) -> [Property] {
        var properties: [Property] = []
        var witnessCount = 0
        for item in declaration.memberBlock.members {
            guard let variable = item.decl.as(VariableDeclSyntax.self) else { continue }
            if isStatic(variable) { continue }
            let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)
            let keyAttributes = attributes(of: variable, named: "ExCodableKey")
            for duplicate in keyAttributes.dropFirst() {
                problems.report(.duplicateKey, at: duplicate)
            }
            let specified = codableSpec(of: variable)
            let excepted = hasAttribute(variable, named: "ExCodableExcept")
            // `.allKeys` codes every stored property; `@ExCodableExcept` opts one back out.
            // A `let` with an initializer stays a fixed field: re-assigning it in `init(from:)` is
            // rejected for explicit keys, so `.allKeys` must not turn it into an implicit key either.
            let implicit = allKeys && !excepted
            let codable = specified ?? (implicit ? Property.implicitSpec : nil)
            for binding in variable.bindings {
                guard isStoredBinding(binding) else {
                    if specified != nil {
                        problems.report(.keyOnNonStoredProperty, at: binding.pattern)
                    }
                    else if implicit {
                        problems.report(.allKeysNonStoredProperty(binding.pattern.trimmedDescription), at: binding.pattern)
                    }
                    continue
                }
                guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                    if specified != nil {
                        problems.report(.keyOnPatternProperty, at: binding.pattern)
                    }
                    else if implicit {
                        problems.report(.allKeysPatternProperty, at: binding.pattern)
                    }
                    continue
                }
                let type = binding.typeAnnotation?.type.trimmedDescription
                let `default` = binding.initializer?.value.trimmedDescription
                if isLet, `default` != nil, specified != nil {
                    problems.report(.keyOnLetWithValue(name), at: binding.pattern)
                    continue
                }
                if isLet, `default` != nil {
                    continue
                }
                // A default exists to absorb a failed decode, and `strictType` asks for the failure to be reported.
                if let specified, specified.strictType == "true", specified.`default` != nil || `default` != nil,
                   let attribute = keyAttributes.first {
                    problems.report(.defaultWithStrictType, at: attribute)
                }
                let access = accessLevel(of: variable.modifiers)
                // A `private` or `fileprivate` variable with a default is already initialized.
                // Swift does not add it to the memberwise initializer, so the initializer stays usable from other files.
                let memberwise = !(`default` != nil && access.rawValue <= Access.fileprivate.rawValue)
                var witness: String?
                if type == nil {
                    guard `default` != nil else {
                        problems.report(.missingTypeAndValue(name), at: binding.pattern)
                        continue
                    }
                    witness = "field\(witnessCount)"
                    witnessCount += 1
                }
                properties.append(Property(access: access, memberwise: memberwise, name: name, type: type, default: `default`, codable: codable, witness: witness))
            }
        }
        return properties
    }
    
    // `willSet` and `didSet` keep the property stored. A getter or setter does not.
    private static func isStoredBinding(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = binding.accessorBlock else { return true }
        guard case let .accessors(accessors) = accessorBlock.accessors, !accessors.isEmpty else { return false }
        return accessors.allSatisfy { accessor in
            return switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet): true
                default: false
            }
        }
    }
    
    // Only `@MainActor` is recognized: any other global actor is an arbitrary name that a macro can not tell
    // from an unrelated attribute. For those, declare the isolated conformance yourself, for example
    // `struct S: @MyActor Codable`.
    private static func isMainActor(_ declaration: some DeclGroupSyntax) -> Bool {
        declaration.attributes.contains { element in
            element.as(AttributeSyntax.self).map { attributeName($0) == "MainActor" } ?? false
        }
    }
    
    private static func hasInitializer(_ declaration: some DeclGroupSyntax) -> Bool {
        declaration.memberBlock.members.contains { $0.decl.is(InitializerDeclSyntax.self) }
    }
    
    private static func attributes(of variable: VariableDeclSyntax, named target: String) -> [AttributeSyntax] {
        variable.attributes.compactMap { element in
            guard let attribute = element.as(AttributeSyntax.self), attributeName(attribute) == target else { return nil }
            return attribute
        }
    }
    
    // An argument that is not one of these is rejected by the compiler before the macro runs, with its own message.
    private static func codableSpec(of variable: VariableDeclSyntax) -> CodableSpec? {
        guard let attribute = attributes(of: variable, named: "ExCodableKey").first else { return nil }
        var keys: [String] = []
        var `default`: String?
        var strictType = "false"
        var encode, decode: String?
        for argument in labeledArguments(of: attribute) ?? [] {
            let expression = argument.expression
            switch argument.label?.text {
                case "default":
                    `default` = expression.trimmedDescription
                case "strictType":
                    strictType = boolLiteral(expression)
                case "encode":
                    encode = expression.trimmedDescription
                case "decode":
                    decode = expression.trimmedDescription
                case nil:
                    keys.append(keyExpression(expression))
                default:
                    break
            }
        }
        return CodableSpec(keys: keys, default: `default`, strictType: strictType, encode: encode, decode: decode)
    }
    
    private static func labeledArguments(of attribute: AttributeSyntax) -> LabeledExprListSyntax? {
        if let arguments = attribute.arguments,
           case let .argumentList(list) = arguments { return list }
        return nil
    }
    
    private static func boolLiteral(_ expression: ExprSyntax) -> String {
        if expression.is(NilLiteralExprSyntax.self) { return "false" }
        if let literal = expression.as(BooleanLiteralExprSyntax.self) { return literal.literal.text }
        return expression.trimmedDescription
    }
    
    private static func keyExpression(_ expression: ExprSyntax) -> String {
        if let literal = expression.as(StringLiteralExprSyntax.self),
           literal.segments.allSatisfy({ if case .stringSegment = $0 { return true } else { return false } }) {
            return literal.trimmedDescription
        }
        return "ExCodableRuntime._keyString(\(expression.trimmedDescription))"
    }
    
    private static func bareIdentifier(_ name: String) -> String {
        var name = name
        while name.hasPrefix("`"), name.hasSuffix("`"), name.count >= 2 {
            name = String(name.dropFirst().dropLast())
        }
        return name
    }
    
    private static func escaped(_ name: String) -> String { "`\(bareIdentifier(name))`" }
    
    private static let protocolNames: Set<String> = [
        "Equatable", "Hashable", "Comparable", "Codable", "Decodable", "Encodable",
        "Sendable", "Identifiable", "CustomStringConvertible", "CustomDebugStringConvertible",
        "Error", "LocalizedError", "CaseIterable", "OptionSet", "RawRepresentable",
        "CodingKey", "Observable", "AnyObject", "TextOutputStreamable",
        "Collection", "Sequence", "Numeric", "AdditiveArithmetic", "Strideable",
        "ExpressibleByNilLiteral", "ExpressibleByStringLiteral", "ExpressibleByIntegerLiteral",
        "ExpressibleByBooleanLiteral", "ExpressibleByFloatLiteral", "ExpressibleByArrayLiteral",
        "ExpressibleByDictionaryLiteral", "NSObjectProtocol", "NSCoding", "NSSecureCoding",
    ]
    
    private static func hasSuperclass(_ declaration: some DeclGroupSyntax) -> Bool {
        guard let classDecl = declaration.as(ClassDeclSyntax.self),
              let inherited = classDecl.inheritanceClause?.inheritedTypes.first?.type else { return false }
        // A superclass is a bare type name. An attribute (`@MainActor Codable`, `@unchecked Sendable`) or a
        // specifier (`any P`, `~Copyable`) only appears on a protocol.
        if inherited.is(AttributedTypeSyntax.self) || inherited.is(SomeOrAnyTypeSyntax.self) || inherited.is(SuppressedTypeSyntax.self) {
            return false
        }
        if let identifier = inherited.as(IdentifierTypeSyntax.self), protocolNames.contains(identifier.name.text) {
            return false
        }
        return true
    }
    
    private static func genericParameterClause(of declaration: some DeclGroupSyntax) -> GenericParameterClauseSyntax? {
        if let decl = declaration.as(StructDeclSyntax.self) { return decl.genericParameterClause }
        if let decl = declaration.as(ClassDeclSyntax.self) { return decl.genericParameterClause }
        return nil
    }
    
    private static func genericWhereClause(of declaration: some DeclGroupSyntax) -> GenericWhereClauseSyntax? {
        if let decl = declaration.as(StructDeclSyntax.self) { return decl.genericWhereClause }
        if let decl = declaration.as(ClassDeclSyntax.self) { return decl.genericWhereClause }
        return nil
    }
    
    private static func inheritanceClause(of declaration: some DeclGroupSyntax) -> InheritanceClauseSyntax? {
        if let decl = declaration.as(StructDeclSyntax.self) { return decl.inheritanceClause }
        if let decl = declaration.as(ClassDeclSyntax.self) { return decl.inheritanceClause }
        return nil
    }
    
    private static func conformanceNames(in type: TypeSyntax) -> Set<String> {
        if let composition = type.as(CompositionTypeSyntax.self) {
            var names: Set<String> = []
            for element in composition.elements {
                names.formUnion(conformanceNames(in: element.type))
            }
            return names
        }
        if let some = type.as(SomeOrAnyTypeSyntax.self) {
            return conformanceNames(in: some.constraint)
        }
        if let attributed = type.as(AttributedTypeSyntax.self) {
            return conformanceNames(in: attributed.baseType)
        }
        if let ident = type.as(IdentifierTypeSyntax.self) {
            return [ident.name.text]
        }
        if let member = type.as(MemberTypeSyntax.self) {
            return [member.name.text]
        }
        return []
    }
    
    // Type parameters that are not already constrained to `Codable`.
    // Value parameters (`let n: Int`) and parameter packs are left alone.
    private static func missingCodableParameters(of declaration: some DeclGroupSyntax) -> [String] {
        guard let parameters = genericParameterClause(of: declaration)?.parameters else { return [] }
        var codable: Set<String> = []
        var decodable: Set<String> = []
        var encodable: Set<String> = []
        func record(_ name: String, _ protocols: Set<String>) {
            if protocols.contains("Codable") { codable.insert(name) }
            if protocols.contains("Decodable") { decodable.insert(name) }
            if protocols.contains("Encodable") { encodable.insert(name) }
        }
        var names: [String] = []
        for parameter in parameters {
            guard parameter.specifier == nil else { continue }
            let name = parameter.name.text
            names.append(name)
            if let inherited = parameter.inheritedType {
                record(name, conformanceNames(in: inherited))
            }
        }
        if let requirements = genericWhereClause(of: declaration)?.requirements {
            for requirement in requirements {
                guard case let .conformanceRequirement(conformance) = requirement.requirement,
                      let name = conformance.leftType.as(IdentifierTypeSyntax.self)?.name.text else { continue }
                record(name, conformanceNames(in: conformance.rightType))
            }
        }
        return names.filter { !(codable.contains($0) || (decodable.contains($0) && encodable.contains($0))) }
    }
    
    private static func declaresCodable(_ declaration: some DeclGroupSyntax) -> Bool {
        guard let inherited = inheritanceClause(of: declaration)?.inheritedTypes else { return false }
        for type in inherited {
            let names = conformanceNames(in: type.type)
            if !names.isDisjoint(with: ["Codable", "Decodable", "Encodable"]) {
                return true
            }
        }
        return false
    }
    
    private static func genericCodableWhere(of declaration: some DeclGroupSyntax, at node: AttributeSyntax, into problems: inout Problems) -> String {
        let missing = missingCodableParameters(of: declaration)
        guard !missing.isEmpty else { return "" }
        if declaresCodable(declaration) {
            problems.report(.genericNotCodable(missing.joined(separator: ", ")), at: node)
            return ""
        }
        return " where " + missing.map { "\($0): Codable" }.joined(separator: ", ")
    }
    
    // Getter access. `private(set)` and the other setter modifiers are ignored.
    private static func accessLevel(of modifiers: DeclModifierListSyntax) -> Access {
        var level = Access.internal
        for modifier in modifiers {
            if modifier.detail != nil { continue }
            switch modifier.name.text {
                case "private": level = .private
                case "fileprivate": level = .fileprivate
                case "internal": level = .internal
                case "package": level = .package
                case "public", "open": level = .public
                default: break
            }
        }
        return level
    }
    
    // `private` if any parameter is private, `fileprivate` if any is fileprivate, otherwise no wider than `internal` or the type.
    private static func memberwiseAccess(type: Access, parameters: [Access]) -> Access {
        var level = Access.internal
        for parameter in parameters {
            if parameter == .private {
                level = .private
                break
            }
            if parameter == .fileprivate {
                level = .fileprivate
            }
        }
        return type.rawValue < level.rawValue ? type : level
    }
    
    // Interpolating an empty string into a multi-line literal leaves a line with no indentation,
    // so an empty body must drop the line instead of rendering a blank one.
    private static func append(lines: String) -> String {
        lines.isEmpty ? "" : "\n\(lines)"
    }
    
    private static func defaultsEnum(for properties: [Property]) -> String? {
        let witnessed = properties.filter { $0.witness != nil }
        guard !witnessed.isEmpty else { return nil }
        let fields = witnessed.map { property in
            """
                struct \(property.witness!): Default {
                    static let `default` = \(property.`default`!)
                }
            """
        }.joined(separator: "\n")
        return """
        enum __ExCodableMemberDefaults {
            protocol Default {
                associatedtype Value
                static var `default`: Value { get }
            }\(append(lines: fields))
        }
        """
    }
    
    private static func memberwiseInit(for properties: [Property], typeAccess: Access) -> String {
        let included = properties.filter(\.memberwise)
        let parameters = included.map { property -> String in
            let label = escaped(property.name)
            if let type = property.type {
                if let `default` = property.`default` {
                    return "\(label): \(type) = \(`default`)"
                }
                if type.hasSuffix("!") {
                    return "\(label): \(type) = nil"
                }
                return "\(label): \(type)"
            }
            let witness = property.witness!
            return "\(label): Self.__ExCodableMemberDefaults.\(witness).Value = Self.__ExCodableMemberDefaults.\(witness).`default`"
        }.joined(separator: ", ")
        let assignments = included.map { property in
            let name = escaped(property.name)
            return "    self.\(name) = \(name)"
        }.joined(separator: "\n")
        let keyword = memberwiseAccess(type: typeAccess, parameters: included.map(\.access)).memberwisePrefix
        return """
        \(keyword)init(\(parameters)) {\(append(lines: assignments))
        }
        """
    }
    
    private static func decodeInit(for properties: [Property], kind: Kind, hasSuperclass: Bool, access: String, genericWhere: String = "") -> String {
        let codable = properties.filter { $0.codable != nil }
        var lines: [String] = []
        if !codable.isEmpty {
            lines.append("    let exCodableTypeConverter = ExCodableRuntime._converter(of: Self.self)")
        }
        for property in codable {
            lines.append(decodeStatement(for: property))
        }
        if hasSuperclass {
            lines.append("    try super.init(from: decoder)")
        }
        let body = lines.joined(separator: "\n")
        let constraint = kind == .class ? genericWhere : ""
        let signature = kind == .class ? "\(access)required init(from decoder: Decoder) throws\(constraint)" : "\(access)init(from decoder: Decoder) throws"
        return if body.isEmpty {
            """
            \(signature) {
            }
            """
        }
        else {
            """
            \(signature) {\(append(lines: body))
            }
            """
        }
    }
    
    private static func decodeStatement(for property: Property) -> String {
        let spec = property.codable!
        let keys = spec.keys.isEmpty ? [StringLiteralExprSyntax(content: bareIdentifier(property.name)).description] : spec.keys
        let keyList = keys.joined(separator: ", ")
        let `default` = spec.`default` ?? property.`default`
        let optional = isOptional(property) || `default` != nil
        let name = escaped(property.name)
        var call = "ExCodableRuntime._decode("
        if spec.decode == nil, let metatype = metatype(of: property) {
            call += "\(metatype), "
        }
        call += "from: decoder, keys: [\(keyList)], optional: \(optional), strictType: \(spec.strictType), converter: exCodableTypeConverter"
        if let decode = spec.decode {
            call += ", customDecode: \(decode)"
        }
        call += ")"
        return if let `default` {
            "    self.\(name) = try \(call) ?? \(`default`)"
        }
        else if isOptional(property) {
            "    self.\(name) = try \(call) ?? nil // !!!: flattens `T??` back to `T`"
        }
        else {
            "    self.\(name) = try \(call)!"
        }
    }
    
    // `!` counts as required: an implicitly unwrapped optional promises a value, and treating it as
    // optional would silently disable the very check the declaration asks for.
    private static func isOptional(_ property: Property) -> Bool {
        guard let type = property.type else { return false }
        return type.hasSuffix("?") || type.hasPrefix("Optional<")
    }
    
    private static func metatype(of property: Property) -> String? {
        if let type = property.type {
            if type.hasSuffix("!") {
                let inner = String(type.dropLast())
                return "Optional<\(inner)>.self"
            }
            return "(\(type)).self"
        }
        if let witness = property.witness {
            return "Self.__ExCodableMemberDefaults.\(witness).Value.self"
        }
        return nil
    }
    
    private static func encodeFunction(for properties: [Property], kind: Kind, hasSuperclass: Bool, access: String, genericWhere: String = "") -> String {
        let codable = properties.filter { $0.codable != nil }
        var lines: [String] = []
        for property in codable {
            lines.append(encodeStatement(for: property))
        }
        if hasSuperclass {
            lines.append("    try super.encode(to: encoder)")
        }
        let body = lines.joined(separator: "\n")
        let override = (kind == .class && hasSuperclass) ? "override " : ""
        let constraint = kind == .class ? genericWhere : ""
        return if body.isEmpty {
            """
            \(access)\(override)func encode(to encoder: Encoder) throws\(constraint) {
                ExCodableRuntime._encodeEmpty(encoder)
            }
            """
        }
        else {
            """
            \(access)\(override)func encode(to encoder: Encoder) throws\(constraint) {\(append(lines: body))
            }
            """
        }
    }
    
    private static func encodeStatement(for property: Property) -> String {
        let spec = property.codable!
        let key = spec.keys.first ?? StringLiteralExprSyntax(content: bareIdentifier(property.name)).description
        let optional = isOptional(property)
        var call = "ExCodableRuntime._encode(self.\(escaped(property.name)), to: encoder, for: \(key), optional: \(optional), strictType: \(spec.strictType)"
        if let encode = spec.encode {
            call += ", customEncode: \(encode)"
        }
        call += ")"
        return "    try \(call)"
    }
}
