//
//  ExCodableMacro.swift
//  ExCodable
//
//  Created by Míng on 2021-02-10.
//  Copyright (c) 2021 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import Foundation

/// Generates `init(from:)`, `encode(to:)`, and a memberwise `init` for a struct or class.
/// Properties opt in with `@ExCodable`.
@attached(member, names: arbitrary)
@attached(extension, conformances: Decodable, Encodable, names: named(init(from:)), named(encode(to:)))
public macro ExCodableEnabled() = #externalMacro(module: "ExCodableMacros", type: "ExCodableEnabledMacro")

@attached(peer, names: arbitrary)
public macro ExCodable(
    _ keys: String...,
    nonnull: Bool? = nil,
    throws: Bool? = nil
) = #externalMacro(module: "ExCodableMacros", type: "ExCodablePropertyMacro")

@attached(peer, names: arbitrary)
public macro ExCodable<Value>(
    _ keys: String...,
    nonnull: Bool? = nil,
    throws: Bool? = nil,
    encode: ((Encoder, Value) throws -> Void)?,
    decode: ((Decoder) throws -> Value?)?
) = #externalMacro(module: "ExCodableMacros", type: "ExCodablePropertyMacro")

@attached(peer, names: arbitrary)
public macro ExCodable<Value>(
    _ keys: String...,
    nonnull: Bool? = nil,
    throws: Bool? = nil,
    encode: ((Encoder, Value) throws -> Void)?
) = #externalMacro(module: "ExCodableMacros", type: "ExCodablePropertyMacro")

@attached(peer, names: arbitrary)
public macro ExCodable<Value>(
    _ keys: String...,
    nonnull: Bool? = nil,
    throws: Bool? = nil,
    decode: ((Decoder) throws -> Value?)?
) = #externalMacro(module: "ExCodableMacros", type: "ExCodablePropertyMacro")

@attached(peer, names: arbitrary)
public macro ExCodable(
    _ key: any CodingKey,
    _ keys: any CodingKey...,
    nonnull: Bool? = nil,
    throws: Bool? = nil
) = #externalMacro(module: "ExCodableMacros", type: "ExCodablePropertyMacro")

@attached(peer, names: arbitrary)
public macro ExCodable<Value>(
    _ key: any CodingKey,
    _ keys: any CodingKey...,
    nonnull: Bool? = nil,
    throws: Bool? = nil,
    encode: ((Encoder, Value) throws -> Void)?,
    decode: ((Decoder) throws -> Value?)?
) = #externalMacro(module: "ExCodableMacros", type: "ExCodablePropertyMacro")

@attached(peer, names: arbitrary)
public macro ExCodable<Value>(
    _ key: any CodingKey,
    _ keys: any CodingKey...,
    nonnull: Bool? = nil,
    throws: Bool? = nil,
    encode: ((Encoder, Value) throws -> Void)?
) = #externalMacro(module: "ExCodableMacros", type: "ExCodablePropertyMacro")

@attached(peer, names: arbitrary)
public macro ExCodable<Value>(
    _ key: any CodingKey,
    _ keys: any CodingKey...,
    nonnull: Bool? = nil,
    throws: Bool? = nil,
    decode: ((Decoder) throws -> Value?)?
) = #externalMacro(module: "ExCodableMacros", type: "ExCodablePropertyMacro")
