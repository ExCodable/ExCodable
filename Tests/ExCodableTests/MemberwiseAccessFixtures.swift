//
//  MemberwiseAccessFixtures.swift
//  ExCodable
//
//  Created by Míng on 2026-10-22.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import Foundation
import ExCodable

@ExCodable
struct MemberwisePrivateSecret {
    @ExCodableKey
    private let secret: Int
}

@ExCodable
struct MemberwiseFileprivateSecret {
    @ExCodableKey
    fileprivate let secret: Int
}

@ExCodable
public struct MemberwisePublicID {
    @ExCodableKey
    public let id: Int
    private var note = "x"
}

extension MemberwisePrivateSecret {
    static func roundTrip() throws -> Int {
        let value = MemberwisePrivateSecret(secret: 3)
        let data = try value.encoded() as Data
        return try MemberwisePrivateSecret.decoded(from: data).secret
    }
}

extension MemberwiseFileprivateSecret {
    static func roundTrip() throws -> Int {
        let value = MemberwiseFileprivateSecret(secret: 4)
        let data = try value.encoded() as Data
        return try MemberwiseFileprivateSecret.decoded(from: data).secret
    }
}
