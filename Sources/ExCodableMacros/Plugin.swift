import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ExCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ExCodableMacro.self,
        ExCodableKeyMacro.self,
    ]
}
