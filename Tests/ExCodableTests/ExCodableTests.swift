//
//  ExCodableTests.swift
//  ExCodable
//
//  Created by Mr. Ming on 2021-02-10.
//  Copyright (c) 2021 Mr. Ming <minglq.9@gmail.com>. Released under the MIT license.
//

import XCTest

@testable
import ExCodable

final class ExCodableTests: XCTestCase {
    func testExCodable() {
        XCTAssertEqual(ExCodable().text, "Hello, ExCodable!")
    }

    static var allTests = [
        ("testExCodable", testExCodable),
    ]
}
