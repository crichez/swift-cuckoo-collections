//
//  CuckooSetTests.swift
//  CuckooSet
//
//  Created by Christopher Richez on January 5th, 2021
//

import CuckooCollections
import XCTest

/// Tests the custom methods of the `CuckooSet` type.
class CuckooSetTests: XCTestCase {
    /// Tests whether a single inserted object is contained in the set.
    func testInsertOne() {
        var cuckooSet = CuckooSet<Double>()
        cuckooSet.insert(1.2)
        XCTAssertTrue(cuckooSet.contains(1.2))
    }

    /// Tests whether requesting an insert operation that would require the set to be expanded
    /// several times still completes the insertion successfully.
    func testInsertMany() {
        var cuckooSet = CuckooSet<Int>()
        for number in 1 ... 10_000 {
            cuckooSet.insert(number)
        }
    }
}