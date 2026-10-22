//
//  MemberwiseAccessTests.swift
//  ExCodable
//
//  Created by Míng on 2026-10-22.
//  Copyright (c) 2026 Míng <i+ExCodable@iwill.im>. Released under the MIT license.
//

import XCTest
import ExCodable

final class MemberwiseAccessTests: XCTestCase {
    
    func testPrivateAndFileprivateInitializers() throws {
        XCTAssertEqual(try MemberwisePrivateSecret.roundTrip(), 3)
        XCTAssertEqual(try MemberwiseFileprivateSecret.roundTrip(), 4)
    }
    
    /// Another file in the same module can call the initializer.
    /// The private variable with a default is not a parameter, so it does not make the initializer private.
    func testInternalMemberwiseInitFromAnotherFile() throws {
        let value = MemberwisePublicID(id: 7)
        XCTAssertEqual(value.id, 7)
        let data = try value.encoded() as Data
        XCTAssertEqual(try MemberwisePublicID.decoded(from: data).id, 7)
    }
}
