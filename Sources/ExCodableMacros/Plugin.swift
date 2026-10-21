//
//  ExCodableMacros.swift
//  ExCodable
//
//  Created by Míng on 2026-10-22.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ExCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ExCodableMacro.self,
        ExCodableKeyMacro.self,
    ]
}
