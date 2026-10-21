import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ExCodableEnabledMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try ExCodableEnabledExpansion.members(of: declaration, attribute: node)
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try ExCodableEnabledExpansion.extensions(of: declaration, type: type, protocols: protocols, attribute: node)
    }
}

public struct ExCodablePropertyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(VariableDeclSyntax.self) else {
            throw ExCodableMacroError.message("@ExCodable can only be applied to a stored property")
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

private enum ExCodableEnabledExpansion {
    private struct Property {
        var name: String
        var type: String?
        var defaultExpr: String?
        var codable: CodableSpec?
        var witness: String?
    }

    private struct CodableSpec {
        var keys: [String]
        var nonnull: String
        var throwsFlag: String
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
            decls.append(DeclSyntax(stringLiteral: decodeInit(for: properties, kind: .class, hasSuperclass: superclass, access: access)))
            decls.append(DeclSyntax(stringLiteral: encodeFunction(for: properties, kind: .class, hasSuperclass: superclass, access: access)))
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
            throw ExCodableMacroError.message("@ExCodableEnabled can only be applied to a struct or class")
        }
        if declaration.is(ClassDeclSyntax.self) {
            guard !protocols.isEmpty else { return [] }
            let conformance = protocols.map(\.trimmedDescription).joined(separator: ", ")
            return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: "extension \(type.trimmedDescription): \(conformance) {}"))]
        }
        let properties = try properties(of: declaration, attribute: attribute)
        let access = typeAccess(of: declaration)
        let conformance = protocols.isEmpty ? "" : ": " + protocols.map(\.trimmedDescription).joined(separator: ", ")
        let source = """
        extension \(type.trimmedDescription)\(conformance) {
        \(decodeInit(for: properties, kind: .struct, hasSuperclass: false, access: access))

        \(encodeFunction(for: properties, kind: .struct, hasSuperclass: false, access: access))
        }
        """
        return [try ExtensionDeclSyntax(SyntaxNodeString(stringLiteral: source))]
    }

    private enum Kind { case `struct`, `class` }

    private static func properties(of declaration: some DeclGroupSyntax, attribute: AttributeSyntax) throws -> [Property] {
        guard let memberBlock = memberBlock(of: declaration) else {
            throw ExCodableMacroError.message("@ExCodableEnabled can only be applied to a struct or class")
        }
        let assignsAll = declaration.is(StructDeclSyntax.self) && !hasInitializer(declaration)
        var properties: [Property] = []
        var witnessCount = 0
        for item in memberBlock.members {
            guard let variable = item.decl.as(VariableDeclSyntax.self) else { continue }
            let modifiers = variable.modifiers.map(\.name.text)
            if modifiers.contains("static") || modifiers.contains("class") { continue }
            let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)
            let codable = try codableSpec(of: variable)
            for binding in variable.bindings {
                guard binding.accessorBlock == nil else {
                    if codable != nil {
                        throw ExCodableMacroError.message("@ExCodable requires a stored property")
                    }
                    continue
                }
                guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                    if codable != nil {
                        throw ExCodableMacroError.message("@ExCodable requires a named stored property")
                    }
                    continue
                }
                let type = binding.typeAnnotation?.type.trimmedDescription
                let defaultExpr = binding.initializer?.value.trimmedDescription
                if isLet, defaultExpr != nil, codable != nil || assignsAll {
                    throw ExCodableMacroError.message("@ExCodableEnabled cannot assign \(name) because the let already has a default value. Remove the default; the generated initializer sets the property.")
                }
                var witness: String?
                if type == nil {
                    guard defaultExpr != nil else {
                        throw ExCodableMacroError.message("@ExCodableEnabled requires a type or a default value for \(name)")
                    }
                    witness = "field\(witnessCount)"
                    witnessCount += 1
                }
                properties.append(Property(name: name, type: type, defaultExpr: defaultExpr, codable: codable, witness: witness))
            }
        }
        return properties
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
            guard name == "ExCodable" || name.hasSuffix(".ExCodable") else { continue }
            var keys: [String] = []
            var nonnull = "false"
            var throwsFlag = "false"
            var encode: String?
            var decode: String?
            if let arguments = labeledArguments(of: attribute) {
                for argument in arguments {
                    let expression = argument.expression
                    switch argument.label?.text {
                    case "nonnull":
                        nonnull = boolLiteral(expression)
                    case "throws":
                        throwsFlag = boolLiteral(expression)
                    case "encode":
                        encode = expression.trimmedDescription
                    case "decode":
                        decode = expression.trimmedDescription
                    case nil:
                        keys.append(keyExpression(expression))
                    default:
                        throw ExCodableMacroError.message("Unknown @ExCodable argument \(argument.label?.text ?? "")")
                    }
                }
            }
            return CodableSpec(keys: keys, nonnull: nonnull, throwsFlag: throwsFlag, encode: encode, decode: decode)
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
                    static let defaultValue = \(property.defaultExpr!)
                }
            """
        }.joined(separator: "\n")
        return """
        enum __ExCodableMemberDefaults {
            protocol Default {
                associatedtype Value
                static var defaultValue: Value { get }
            }
        \(fields)
        }
        """
    }

    private static func memberwiseInit(for properties: [Property]) -> String {
        let parameters = properties.map { property -> String in
            let label = escaped(property.name)
            if let type = property.type {
                if let defaultExpr = property.defaultExpr {
                    return "\(label): \(type) = \(defaultExpr)"
                }
                if type.hasSuffix("!") {
                    return "\(label): \(type) = nil"
                }
                return "\(label): \(type)"
            }
            let witness = property.witness!
            return "\(label): Self.__ExCodableMemberDefaults.\(witness).Value = Self.__ExCodableMemberDefaults.\(witness).defaultValue"
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

    private static func decodeInit(for properties: [Property], kind: Kind, hasSuperclass: Bool, access: String) -> String {
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
        let signature = kind == .class ? "\(access)required init(from decoder: Decoder) throws" : "\(access)init(from decoder: Decoder) throws"
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
        call += "from: decoder, keys: [\(keyList)], nonnull: \(spec.nonnull), throws: \(spec.throwsFlag), converter: exCodableTypeConverter"
        if let decode = spec.decode {
            call += ", customDecode: \(decode)"
        }
        call += ")"
        let name = escaped(property.name)
        if let defaultExpr = property.defaultExpr {
            return """
                    if let exCodableValue = try \(call) {
                        self.\(name) = exCodableValue
                    }
                    else {
                        self.\(name) = \(defaultExpr)
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

    private static func encodeFunction(for properties: [Property], kind: Kind, hasSuperclass: Bool, access: String) -> String {
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
        if body.isEmpty {
            return """
            \(access)\(override)func encode(to encoder: Encoder) throws {
            }
            """
        }
        return """
        \(access)\(override)func encode(to encoder: Encoder) throws {
        \(body)
        }
        """
    }

    private static func encodeStatement(for property: Property) -> String {
        let spec = property.codable!
        let key = spec.keys.first ?? swiftString(bareIdentifier(property.name))
        var call = "ExCodableRuntime.encode(self.\(escaped(property.name)), to: encoder, for: \(key), nonnull: \(spec.nonnull), throws: \(spec.throwsFlag)"
        if let encode = spec.encode {
            call += ", customEncode: \(encode)"
        }
        call += ")"
        return "        try \(call)"
    }
}
