//
//  CuckooStorageTests.swift
//
//
//  Created by Christopher Richez on June 18 2022
//

import XCTest
@testable import CuckooCollections

class CuckooStorageTests: XCTestCase {
    /// Asserts mutating a copy of a set does not mutate the original.
    func testValueSemantics() {
        let original: CuckooSet = ["test", "one", "two"]
        var copy = original
        copy.insert("three")
        XCTAssertFalse(original.contains("three"))
    }

    /// Asserts copies of a set reference the same memory.
    func testReferenceSemantics() {
        let original: CuckooSet = [1.295]
        let copy = original
        XCTAssertEqual(original.buckets.basePointer, copy.buckets.basePointer)
    }
}
