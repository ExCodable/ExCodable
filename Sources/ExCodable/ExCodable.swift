//
//  ExCodable.swift
//  ExCodable
//
//  Created by Míng on 2026-10-22.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

/// # ExCodable
/// 
/// <#swift#> <#codable#> <#json#> <#model#> <#type-inference#>
/// <#macro#> <#key-mapping#> <#coding-key#> <#subscript#>
/// <#alternative-keys#> <#nested-keys#> <#type-conversions#>
/// <#default-value#> <#custom-encoding#> <#custom-decoding#>
/// 
/// - `ExCodable`: A macro generates `init(from:)` and `encode(to:)`.
/// - `ExCodableKey`: A macro associates JSON keys to properties.
/// - `Encodable` & `Decodable` extensions for encoding/decoding from internal/external.
/// - `Encoder` & `Encoder` extensions for encoding/decoding properties one by one.
/// - Supports alternative keys, nested keys, type conversions, nested optionals, default values, custom encoding, custom decoding, etc.
/// 
/// - seealso: [Usage](https://github.com/ExCodable/ExCodable#usage) from the `README.md`
/// - seealso: `ExCodableTests.swift` from the `Tests`
/// - seealso: [Decoding and overriding](https://www.swiftbysundell.com/articles/property-wrappers-in-swift/#decoding-and-overriding)
/// and [Useful Codable extensions](https://www.swiftbysundell.com/tips/useful-codable-extensions/), by John Sundell.

public enum ExCodableOptions {
    case exCodableKeys, allKeys
}

/// @ExCodable + @ExCodableKey
/// @ExCodable(.allKeys) + @ExCodableExcept
@attached(member, names: arbitrary)
@attached(extension, conformances: Decodable, Encodable, names: named(init(from:)), named(encode(to:)))
public macro ExCodable(_ options: ExCodableOptions = .exCodableKeys) = #externalMacro(module: "ExCodableMacros", type: "ExCodableMacro")

/// @ExCodableKey to enable auto encode/decode by @ExCodable
@attached(peer, names: arbitrary)
public macro ExCodableKey(
    _ keys: String...,
    strictType: Bool? = nil
) = #externalMacro(module: "ExCodableMacros", type: "ExCodableKeyMacro")
@attached(peer, names: arbitrary)
public macro ExCodableKey<Value>(
    _ keys: String...,
    default: Value? = nil,
    strictType: Bool? = nil,
    encode: ((Encoder, Value) throws -> Void)? = nil,
    decode: ((Decoder) throws -> Value?)? = nil
) = #externalMacro(module: "ExCodableMacros", type: "ExCodableKeyMacro")

/// @ExCodableExcept to avoid auto encode/decode by @ExCodable(.allKeys)
@attached(peer, names: arbitrary)
public macro ExCodableExcept() = #externalMacro(module: "ExCodableMacros", type: "ExCodableExceptMacro")
