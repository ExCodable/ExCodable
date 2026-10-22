//
//  ExCodableMacros.swift
//  ExCodable
//
//  Created by Míng on 2026-10-22.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

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
        return []
    }
}

private enum ExCodableMacroError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case .message(let message): return message
        }
    }
}

private enum ExCodableExpansion {
    
    private struct Property {
        var name: String
        var type: String?
        var `default`: String?
        var codable: CodableSpec?
        var witness: String?
    }
    
    private struct CodableSpec {
        var keys: [String]
        var `default`: String?
        var nonnull: String
        var `throws`: String
        var encode: String?
        var decode: String?
    }
    
    static func members(of declaration: some DeclGroupSyntax, attribute: AttributeSyntax) throws -> [DeclSyntax] {
        let properties = try properties(of: declaration, attribute: attribute)
        var decls: [DeclSyntax] = []
        if let defaults = defaultsEnum(for: properties) {
            decls.append(DeclSyntax(stringLiteral: defaults))
        }
        if declaration.is(StructDeclSyntax.self), !hasInitializer(declaration) {
            decls.append(DeclSyntax(stringLiteral: memberwiseInit(for: properties)))
        }
        if declaration.is(ClassDeclSyntax.self) {
            let superclass = hasSuperclass(declaration)
            let access = typeAccess(of: declaration)
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
        let access = typeAccess(of: declaration)
        let conformance = protocols.isEmpty ? "" : ": " + protocols.map(\.trimmedDescription).joined(separator: ", ")
        let source = """
        extension \(type.trimmedDescription)\(conformance)\(genericWhere) {
        \(decodeInit(for: properties, kind: .struct, hasSuperclass: false, access: access))
        
        \(encodeFunction(for: properties, kind: .struct, hasSuperclass: false, access: access))
        }
        """
        return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: source))]
    }
    
    private enum Kind { case `struct`, `class` }
    
    private static func properties(of declaration: some DeclGroupSyntax, attribute: AttributeSyntax) throws -> [Property] {
        guard let memberBlock = memberBlock(of: declaration) else {
            throw ExCodableMacroError.message("@ExCodable can only be applied to a struct or class")
        }
        var properties: [Property] = []
        var witnessCount = 0
        for item in memberBlock.members {
            guard let variable = item.decl.as(VariableDeclSyntax.self) else { continue }
            let modifiers = variable.modifiers.map(\.name.text)
            if modifiers.contains("static") || modifiers.contains("class") { continue }
            let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)
            let codable = try codableSpec(of: variable)
            for binding in variable.bindings {
                guard isStoredBinding(binding) else {
                    if codable != nil {
                        throw ExCodableMacroError.message("@ExCodableKey requires a stored property")
                    }
                    continue
                }
                guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                    if codable != nil {
                        throw ExCodableMacroError.message("@ExCodableKey requires a named stored property")
                    }
                    continue
                }
                let type = binding.typeAnnotation?.type.trimmedDescription
                let `default` = binding.initializer?.value.trimmedDescription
                if isLet, `default` != nil, codable != nil {
                    throw ExCodableMacroError.message("@ExCodable cannot assign \(name) because the let already has a default value. Remove the default; the generated initializer sets the property.")
                }
                if isLet, `default` != nil {
                    continue
                }
                var witness: String?
                if type == nil {
                    guard `default` != nil else {
                        throw ExCodableMacroError.message("@ExCodable requires a type or a default value for \(name)")
                    }
                    witness = "field\(witnessCount)"
                    witnessCount += 1
                }
                properties.append(Property(name: name, type: type, `default`: `default`, codable: codable, witness: witness))
            }
        }
        return properties
    }
    
    /// `willSet` and `didSet` keep the property stored. A getter or setter does not.
    private static func isStoredBinding(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = binding.accessorBlock else { return true }
        guard case .accessors(let accessors) = accessorBlock.accessors, !accessors.isEmpty else { return false }
        return accessors.allSatisfy { accessor in
            switch accessor.accessorSpecifier.tokenKind {
            case .keyword(.willSet), .keyword(.didSet):
                return true
            default:
                return false
            }
        }
    }
    
    private static func memberBlock(of declaration: some DeclGroupSyntax) -> MemberBlockSyntax? {
        if let decl = declaration.as(StructDeclSyntax.self) { return decl.memberBlock }
        if let decl = declaration.as(ClassDeclSyntax.self) { return decl.memberBlock }
        return nil
    }
    
    private static func hasInitializer(_ declaration: some DeclGroupSyntax) -> Bool {
        guard let memberBlock = memberBlock(of: declaration) else { return false }
        return memberBlock.members.contains { $0.decl.is(InitializerDeclSyntax.self) }
    }
    
    private static func codableSpec(of variable: VariableDeclSyntax) throws -> CodableSpec? {
        for attribute in variable.attributes {
            guard let attribute = attribute.as(AttributeSyntax.self) else { continue }
            let name = attribute.attributeName.trimmedDescription
            guard name == "ExCodableKey" || name.hasSuffix(".ExCodableKey") else { continue }
            var keys: [String] = []
            var `default`: String?
            var hasNonnull = false
            var nonnull = "false"
            var hasThrows = false
            var `throws` = "false"
            var encode: String?
            var decode: String?
            if let arguments = labeledArguments(of: attribute) {
                for argument in arguments {
                    let expression = argument.expression
                    switch argument.label?.text {
                    case "default":
                        `default` = expression.trimmedDescription
                    case "nonnull":
                        hasNonnull = true
                        nonnull = boolLiteral(expression)
                    case "throws":
                        hasThrows = true
                        `throws` = boolLiteral(expression)
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
            if `default` != nil, hasNonnull || hasThrows {
                throw ExCodableMacroError.message("@ExCodableKey cannot use default together with nonnull or throws")
            }
            return CodableSpec(keys: keys, default: `default`, nonnull: nonnull, throws: `throws`, encode: encode, decode: decode)
        }
        return nil
    }
    
    private static func labeledArguments(of attribute: AttributeSyntax) -> LabeledExprListSyntax? {
        guard let arguments = attribute.arguments else { return nil }
        if case .argumentList(let list) = arguments { return list }
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
    
    private static func swiftString(_ value: String) -> String {
        var result = "\""
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default: result.unicodeScalars.append(scalar)
            }
        }
        result += "\""
        return result
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
    
    private static func typeAccess(of declaration: some DeclGroupSyntax) -> String {
        let names = declaration.modifiers.map(\.name.text)
        if names.contains("open") || names.contains("public") { return "public " }
        if names.contains("package") { return "package " }
        if names.contains("private") { return "private " }
        if names.contains("fileprivate") { return "fileprivate " }
        return ""
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
    
    private static func memberwiseInit(for properties: [Property]) -> String {
        let parameters = properties.map { property -> String in
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
        let assignments = properties.map { property in
            let name = escaped(property.name)
            return "        self.\(name) = \(name)"
        }.joined(separator: "\n")
        return """
        init(\(parameters)) {
        \(assignments)
        }
        """
    }
    
    private static func decodeInit(for properties: [Property], kind: Kind, hasSuperclass: Bool, access: String, genericWhere: String = "") -> String {
        let codable = properties.filter { $0.codable != nil }
        var lines: [String] = []
        if !codable.isEmpty {
            lines.append("        let exCodableTypeConverter = ExCodableRuntime.converter(of: Self.self)")
        }
        for property in codable {
            lines.append(decodeStatement(for: property))
        }
        if hasSuperclass {
            lines.append("        try super.init(from: decoder)")
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
        let keys = spec.keys.isEmpty ? [swiftString(bareIdentifier(property.name))] : spec.keys
        let keyList = keys.joined(separator: ", ")
        var call = "ExCodableRuntime.decode("
        if spec.decode == nil, let metatype = metatype(of: property) {
            call += "\(metatype), "
        }
        call += "from: decoder, keys: [\(keyList)], nonnull: \(spec.nonnull), throws: \(spec.`throws`), converter: exCodableTypeConverter"
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
            lines.append("        try super.encode(to: encoder)")
        }
        let body = lines.joined(separator: "\n")
        let override = (kind == .class && hasSuperclass) ? "override " : ""
        let constraint = kind == .class ? genericWhere : ""
        if body.isEmpty {
            return """
            \(access)\(override)func encode(to encoder: Encoder) throws\(constraint) {
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
        let key = spec.keys.first ?? swiftString(bareIdentifier(property.name))
        var call = "ExCodableRuntime.encode(self.\(escaped(property.name)), to: encoder, for: \(key), nonnull: \(spec.nonnull), throws: \(spec.`throws`)"
        if let encode = spec.encode {
            call += ", customEncode: \(encode)"
        }
        call += ")"
        return "        try \(call)"
    }
}
