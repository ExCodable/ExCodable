//
//  ExCodableMacro.swift
//  ExCodable
//
//  Created by Míng on 2026-10-22.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import Foundation

/// Generates `init(from:)`, `encode(to:)`, and a memberwise `init` for a struct or class.
/// Properties opt in with `@ExCodableKey`.
@attached(member, names: arbitrary)
@attached(extension, conformances: Decodable, Encodable, names: named(init(from:)), named(encode(to:)))
public macro ExCodable() = #externalMacro(module: "ExCodableMacros", type: "ExCodableMacro")

@attached(peer, names: arbitrary)
public macro ExCodableKey(
    _ keys: String...,
    nonnull: Bool? = nil,
    throws: Bool? = nil
) = #externalMacro(module: "ExCodableMacros", type: "ExCodableKeyMacro")

@attached(peer, names: arbitrary)
public macro ExCodableKey<Value>(
    _ keys: String...,
    default: Value? = nil,
    nonnull: Bool? = nil,
    throws: Bool? = nil,
    encode: ((Encoder, Value) throws -> Void)? = nil,
    decode: ((Decoder) throws -> Value?)? = nil
) = #externalMacro(module: "ExCodableMacros", type: "ExCodableKeyMacro")
