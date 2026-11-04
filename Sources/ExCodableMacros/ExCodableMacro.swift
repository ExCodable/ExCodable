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
        try ExCodableExpansion.members(of: declaration, attribute: node)
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
        guard declaration.is(VariableDeclSyntax.self) else {
            throw ExCodableMacroError.message("@ExCodableKey can only be applied to a stored property")
        }
        if enclosingTypeIsNotExCodable(in: context) {
            context.diagnose(Diagnostic(node: node, message: ExCodableKeyWithoutExCodable()))
        }
        return []
    }
}

/// `@ExCodableExcept` only does something in `.allKeys` mode.
///
/// - `.allKeys`: the property is left out of coding.
/// - `.exCodableKeys` (default): an unmarked property is already excluded, so the attribute changes
///   nothing and stays silent — writing it or not is the same.
/// - No `@ExCodable` at all: nothing is generated, so the attribute is reported like a stray
///   `@ExCodableKey` would be.
public struct ExCodableExceptMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            throw ExCodableMacroError.message("@ExCodableExcept can only be applied to a stored property")
        }
        if hasAttribute(variable, named: "ExCodableKey") {
            throw ExCodableMacroError.message("@ExCodableExcept cannot be combined with @ExCodableKey")
        }
        if enclosingTypeIsNotExCodable(in: context) {
            context.diagnose(Diagnostic(node: node, message: ExCodableExceptWithoutExCodable()))
        }
        return []
    }
}

/// Whether `@ExCodable` was passed `.allKeys`.
///
/// The parameter type is `ExCodableOptions`, so the compiler already rejects anything else;
/// this only has to read the case name. A case reached through a variable or a function call has
/// no name to read, so it is reported instead of being silently treated as `.exCodableKeys`.
private func isAllKeys(_ attribute: AttributeSyntax) throws -> Bool {
    guard let arguments = attribute.arguments,
          case .argumentList(let list) = arguments,
          let expression = list.first?.expression else { return false }
    guard let member = expression.as(MemberAccessExprSyntax.self) else {
        throw ExCodableMacroError.message(
            "@ExCodable cannot evaluate \(expression.trimmedDescription) at compile time. "
            + "Write .allKeys or .exCodableKeys directly."
        )
    }
    return member.declName.baseName.text == "allKeys"
}

/// The attribute name without its module qualifier, so `ExCodable.ExCodable` reads as `ExCodable`.
private func attributeName(_ attribute: AttributeSyntax) -> String {
    let name = attribute.attributeName.trimmedDescription
    return name.split(separator: ".").last.map(String.init) ?? name
}

private func hasAttribute(_ variable: VariableDeclSyntax, named target: String) -> Bool {
    variable.attributes.contains { element in
        element.as(AttributeSyntax.self).map { attributeName($0) == target } ?? false
    }
}

private func isExCodableAttribute(_ attribute: AttributeSyntax) -> Bool {
    attributeName(attribute) == "ExCodable"
}

/// `@ExCodableKey` alone does nothing: the member and extension macros on the enclosing type are
/// what produce `init(from:)` and `encode(to:)`. Returns `true` when no enclosing type (or none of
/// its enclosing types, for nested declarations) carries `@ExCodable`.
private func enclosingTypeIsNotExCodable(in context: some MacroExpansionContext) -> Bool {
    for item in context.lexicalContext.reversed() {
        guard let decl = item.asProtocol(DeclGroupSyntax.self) else { continue }
        if decl.attributes.contains(where: { $0.as(AttributeSyntax.self).map(isExCodableAttribute) ?? false }) {
            return false
        }
    }
    return true
}

struct ExCodableKeyWithoutExCodable: DiagnosticMessage {
    var message: String {
        "@ExCodableKey has no effect because the enclosing type is not marked @ExCodable. "
        + "Add @ExCodable to the type, or remove @ExCodableKey if the property should stay out of coding."
    }
    var diagnosticID: MessageID { MessageID(domain: "ExCodable", id: "keyWithoutExCodable") }
    var severity: DiagnosticSeverity { .warning }
}

struct ExCodableExceptWithoutExCodable: DiagnosticMessage {
    var message: String {
        "@ExCodableExcept has no effect because the enclosing type is not marked @ExCodable. "
        + "Add @ExCodable (with .allKeys to use @ExCodableExcept), or remove the attribute."
    }
    var diagnosticID: MessageID { MessageID(domain: "ExCodable", id: "exceptWithoutExCodable") }
    var severity: DiagnosticSeverity { .warning }
}

private enum ExCodableMacroError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        return switch self {
            case let .message(message): message
        }
    }
}

private enum ExCodableExpansion {
    
    private enum Access: Int {
        case `private` = 0
        case `fileprivate` = 1
        case `internal` = 2
        case `package` = 3
        case `public` = 4
        /// Keyword prefix for a declaration at this level. `internal` needs none.
        var prefix: String {
            return switch self {
                case .private: "private "
                case .fileprivate: "fileprivate "
                case .internal: ""
                case .package: "package "
                case .public: "public "
            }
        }
        /// Swift never synthesizes a `public` or `package` memberwise initializer, so those stay
        /// unmarked rather than being widened or narrowed.
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
        /// `false` for a `private` or `fileprivate` variable that already has a default.
        /// Swift leaves those out of the memberwise initializer.
        var memberwise: Bool
        var name: String
        var type: String?
        var `default`: String?
        var codable: CodableSpec?
        var witness: String?
        /// `.allKeys` codes an unmarked property exactly like an empty `@ExCodableKey`.
        static let implicitSpec = CodableSpec(keys: [], default: nil, nonnull: "false", strictType: "false", encode: nil, decode: nil)
    }
    
    private struct CodableSpec {
        var keys: [String]
        var `default`: String?
        var nonnull, `strictType`: String
        var encode, decode: String?
    }
    
    static func members(of declaration: some DeclGroupSyntax, attribute: AttributeSyntax) throws -> [DeclSyntax] {
        try checkContradictions(of: declaration)
        let properties = try properties(of: declaration, attribute: attribute)
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
            let genericWhere = try genericCodableWhere(of: declaration)
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
            throw ExCodableMacroError.message("@ExCodable can only be applied to a struct or class")
        }
        let genericWhere = try genericCodableWhere(of: declaration)
        if declaration.is(ClassDeclSyntax.self) {
            guard !protocols.isEmpty else { return [] }
            let conformance = protocols.map(\.trimmedDescription).joined(separator: ", ")
            return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: "extension \(type.trimmedDescription): \(conformance)\(genericWhere) {}"))]
        }
        let properties = try properties(of: declaration, attribute: attribute)
        let access = accessLevel(of: declaration.modifiers).prefix
        let conformance = protocols.isEmpty ? "" : ": " + protocols.map(\.trimmedDescription).joined(separator: ", ")
        let source = """
        extension \(type.trimmedDescription)\(conformance)\(genericWhere) {
        \(decodeInit(for: properties, kind: .struct, hasSuperclass: false, access: access))
        \(encodeFunction(for: properties, kind: .struct, hasSuperclass: false, access: access))
        }
        """
        return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: source))]
    }
    
    private static func properties(of declaration: some DeclGroupSyntax, attribute: AttributeSyntax) throws -> [Property] {
        let memberBlock = declaration.memberBlock
        let allKeys = try isAllKeys(attribute)
        var properties: [Property] = []
        var witnessCount = 0
        for item in memberBlock.members {
            guard let variable = item.decl.as(VariableDeclSyntax.self) else { continue }
            let modifiers = variable.modifiers.map(\.name.text)
            if modifiers.contains("static") || modifiers.contains("class") { continue }
            let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)
            let specified = try codableSpec(of: variable)
            let excepted = hasAttribute(variable, named: "ExCodableExcept")
            // `.allKeys` codes every stored property; `@ExCodableExcept` opts one back out.
            // A `let` with an initializer stays a fixed field: re-assigning it in `init(from:)` is
            // rejected for explicit keys, so `.allKeys` must not turn it into an implicit key either.
            let implicit = allKeys && !excepted
            let codable = specified ?? (implicit ? Property.implicitSpec : nil)
            for binding in variable.bindings {
                guard isStoredBinding(binding) else {
                    if specified != nil {
                        throw ExCodableMacroError.message("@ExCodableKey requires a stored property")
                    }
                    if implicit {
                        throw ExCodableMacroError.message("@ExCodable(.allKeys) can only code stored properties. Add @ExCodableExcept to the computed property if that is intended.")
                    }
                    continue
                }
                guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                    if specified != nil {
                        throw ExCodableMacroError.message("@ExCodableKey requires a named stored property")
                    }
                    if implicit {
                        throw ExCodableMacroError.message("@ExCodable(.allKeys) can only code named stored properties. Add @ExCodableExcept if that is intended.")
                    }
                    continue
                }
                let type = binding.typeAnnotation?.type.trimmedDescription
                let `default` = binding.initializer?.value.trimmedDescription
                if isLet, `default` != nil, specified != nil {
                    throw ExCodableMacroError.message("@ExCodable cannot assign \(name) because the let already has a default value. Remove the default; the generated initializer sets the property.")
                }
                if isLet, `default` != nil {
                    continue
                }
                let access = accessLevel(of: variable.modifiers)
                // A private or fileprivate variable with a default is already initialized.
                // Swift does not add it to the memberwise initializer, so the initializer stays usable from other files.
                let memberwise = !(`default` != nil && access.rawValue <= Access.fileprivate.rawValue)
                var witness: String?
                if type == nil {
                    guard `default` != nil else {
                        throw ExCodableMacroError.message("@ExCodable requires a type or a default value for \(name)")
                    }
                    witness = "field\(witnessCount)"
                    witnessCount += 1
                }
                properties.append(Property(access: access, memberwise: memberwise, name: name, type: type, default: `default`, codable: codable, witness: witness))
            }
        }
        return properties
    }
    
    /// `willSet` and `didSet` keep the property stored. A getter or setter does not.
    private static func isStoredBinding(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = binding.accessorBlock else { return true }
        guard case .accessors(let accessors) = accessorBlock.accessors, !accessors.isEmpty else { return false }
        return accessors.allSatisfy { accessor in
            return switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet): true
                default: false
            }
        }
    }
    
    private static func hasInitializer(_ declaration: some DeclGroupSyntax) -> Bool {
        declaration.memberBlock.members.contains { $0.decl.is(InitializerDeclSyntax.self) }
    }
    
    private static func codableSpec(of variable: VariableDeclSyntax) throws -> CodableSpec? {
        for attribute in variable.attributes {
            guard let attribute = attribute.as(AttributeSyntax.self) else { continue }
            guard attributeName(attribute) == "ExCodableKey" else { continue }
            var keys: [String] = []
            var `default`: String?
            var nonnull = "false"
            var `strictType` = "false"
            var encode: String?
            var decode: String?
            if let arguments = labeledArguments(of: attribute) {
                for argument in arguments {
                    let expression = argument.expression
                    switch argument.label?.text {
                        case "default":
                            `default` = expression.trimmedDescription
                        case "nonnull":
                            nonnull = boolLiteral(expression)
                        case "strictType":
                            `strictType` = boolLiteral(expression)
                        case "encode":
                            encode = expression.trimmedDescription
                        case "decode":
                            decode = expression.trimmedDescription
                        case nil:
                            keys.append(keyExpression(expression))
                        default:
                            throw ExCodableMacroError.message("Unknown @ExCodableKey argument \(argument.label?.text ?? "")")
                    }
                }
            }
            return CodableSpec(keys: keys, default: `default`, nonnull: nonnull, strictType: `strictType`, encode: encode, decode: decode)
        }
        return nil
    }
    
    /// A default value exists to absorb a failed decode; `nonnull` and `strictType` both say "do not
    /// absorb this failure", which would leave the default unreachable and the declaration
    /// self-contradictory. Only an explicit `true` conflicts — `nonnull: false` means "off".
    ///
    /// Checked once per type by `members`, never from `codableSpec`: `@ExCodable` expands twice
    /// (member and extension macros), so validating during parsing would report everything twice.
    private static func checkContradictions(of declaration: some DeclGroupSyntax) throws {
        for item in declaration.memberBlock.members {
            guard let variable = item.decl.as(VariableDeclSyntax.self),
                  let spec = try codableSpec(of: variable) else { continue }
            if spec.`default` != nil, spec.nonnull == "true" || spec.`strictType` == "true" {
                throw ExCodableMacroError.message("@ExCodableKey cannot use default together with nonnull or strictType")
            }
        }
    }
    
    private static func labeledArguments(of attribute: AttributeSyntax) -> LabeledExprListSyntax? {
        if let arguments = attribute.arguments,
           case .argumentList(let list) = arguments { return list }
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
        return "ExCodableRuntime.keyString(\(expression.trimmedDescription))"
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
    
    /// Type parameters that are not already constrained to `Codable`.
    /// Value parameters (`let n: Int`) and parameter packs are left alone.
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
                guard case .conformanceRequirement(let conformance) = requirement.requirement,
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
    
    private static func genericCodableWhere(of declaration: some DeclGroupSyntax) throws -> String {
        let missing = missingCodableParameters(of: declaration)
        guard !missing.isEmpty else { return "" }
        if declaresCodable(declaration) {
            let list = missing.joined(separator: ", ")
            throw ExCodableMacroError.message("@ExCodable requires \(list) to conform to Codable. The type already declares Codable, Decodable, or Encodable, so the conformance cannot be conditional.")
        }
        return " where " + missing.map { "\($0): Codable" }.joined(separator: ", ")
    }
    
    /// Getter access. `private(set)` and the other setter modifiers are ignored.
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
    
    /// `private` if any parameter is private, `fileprivate` if any is fileprivate, otherwise no wider than `internal` or the type.
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
            }
        \(fields)
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
        \(keyword)init(\(parameters)) {
        \(assignments)
        }
        """
    }
    
    private static func decodeInit(for properties: [Property], kind: Kind, hasSuperclass: Bool, access: String, genericWhere: String = "") -> String {
        let codable = properties.filter { $0.codable != nil }
        var lines: [String] = []
        if !codable.isEmpty {
            lines.append("    let exCodableTypeConverter = ExCodableRuntime.converter(of: Self.self)")
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
        if body.isEmpty {
            return """
            \(signature) {
            }
            """
        }
        return """
        \(signature) {
        \(body)
        }
        """
    }
    
    private static func decodeStatement(for property: Property) -> String {
        let spec = property.codable!
        let keys = spec.keys.isEmpty ? [StringLiteralExprSyntax(content: bareIdentifier(property.name)).description] : spec.keys
        let keyList = keys.joined(separator: ", ")
        var call = "ExCodableRuntime.decode("
        if spec.decode == nil, let metatype = metatype(of: property) {
            call += "\(metatype), "
        }
        call += "from: decoder, keys: [\(keyList)], nonnull: \(spec.nonnull), strictType: \(spec.`strictType`), converter: exCodableTypeConverter"
        if let decode = spec.decode {
            call += ", customDecode: \(decode)"
        }
        call += ")"
        let name = escaped(property.name)
        if let `default` = spec.`default` ?? property.`default` {
            return """
                if let exCodableValue = try \(call) {
                    self.\(name) = exCodableValue
                }
                else {
                    self.\(name) = \(`default`)
                }
            """
        }
        if let type = property.type, type.hasSuffix("!") || type.hasSuffix("?") || type.hasPrefix("Optional<") {
            return """
                if let exCodableValue = try \(call) {
                    self.\(name) = exCodableValue
                }
                else {
                    self.\(name) = nil
                }
            """
        }
        let missingType = metatype(of: property) ?? "Any.self"
        return """
            guard let exCodableValue = try \(call) else {
                throw DecodingError.valueNotFound(\(missingType), DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "ExCodable expected a value for \(property.name)."))
            }
            self.\(name) = exCodableValue
        """
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
        if body.isEmpty {
            return """
            \(access)\(override)func encode(to encoder: Encoder) throws\(constraint) {
                ExCodableRuntime.openKeyedContainer(encoder)
            }
            """
        }
        return """
        \(access)\(override)func encode(to encoder: Encoder) throws\(constraint) {
        \(body)
        }
        """
    }
    
    private static func encodeStatement(for property: Property) -> String {
        let spec = property.codable!
        let key = spec.keys.first ?? StringLiteralExprSyntax(content: bareIdentifier(property.name)).description
        var call = "ExCodableRuntime.encode(self.\(escaped(property.name)), to: encoder, for: \(key), nonnull: \(spec.nonnull), strictType: \(spec.`strictType`)"
        if let encode = spec.encode {
            call += ", customEncode: \(encode)"
        }
        call += ")"
        return "    try \(call)"
    }
}
