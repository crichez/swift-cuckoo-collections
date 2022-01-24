//
//  SetAlgebraTests.swift
//  SetAlgebraTests
//
//  Created by Christopher Richez on January 18 2022
//

import CuckooCollections
import XCTest

class SetAlgebraTests: XCTestCase {
    func testUnion() throws {
        let set1: CuckooSet<String?> = [nil, "one", "two", "three"]
        let set2: CuckooSet<String?> = ["three", "four", "five", nil]
        let union = set1.union(set2)
        let expectedSet: CuckooSet<String?> = [nil, "one", "two", "three", "four", "five"]
        XCTAssertEqual(expectedSet, union)
    }

    func testIntersection() throws {
        let set1: CuckooSet<String?> = [nil, "one", "two", "three"]
        let set2: CuckooSet<String?> = ["three", "four", "five", nil]
        let intersection = set1.intersection(set2)
        let expectedSet: CuckooSet<String?> = [nil, "three"]
        XCTAssertEqual(expectedSet, intersection)
    }

    func testSymmetricDifference() throws {
        let set1: CuckooSet<String?> = [nil, "one", "two", "three"]
        let set2: CuckooSet<String?> = ["three", "four", "five", nil]
        let symmetricDifference = set1.symmetricDifference(set2)
        let expectedSet: CuckooSet<String?> = ["one", "two", "four", "five"]
        XCTAssertEqual(expectedSet, symmetricDifference)
    }

    func testSubtract() throws {
        let set1: CuckooSet<String?> = [nil, "one", "two", "three"]
        let set2: CuckooSet<String?> = ["three", "four", "five", nil]
        let difference = set1.subtracting(set2)
        let expectedSet: CuckooSet<String?> = ["one", "two"]
        XCTAssertEqual(expectedSet, difference)
    }
}