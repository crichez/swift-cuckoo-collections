//
//  CuckooDictionaryStorageTests.swift
//
//
//  Created by Christopher Richez on June 20 2022
//

import XCTest
@testable import CuckooCollections

class CuckooDictionaryStorageTests: XCTestCase {
    /// Asserts mutating a copy of a set does not mutate the original.
    func testValueSemantics() {
        let original: CuckooDictionary = ["test": 0, "one": 1, "two": 2]
        var copy = original
        copy["three"] = 3
        XCTAssertNil(original["three"])
    }

    /// Asserts copies of a set reference the same memory.
    func testReferenceSemantics() {
        let original: CuckooDictionary = ["value": 1.295]
        let copy = original
        XCTAssertEqual(original.buckets.basePointer, copy.buckets.basePointer)
    }
}