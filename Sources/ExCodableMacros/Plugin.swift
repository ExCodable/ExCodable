import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ExCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ExCodableEnabledMacro.self,
        ExCodablePropertyMacro.self,
    ]
}
