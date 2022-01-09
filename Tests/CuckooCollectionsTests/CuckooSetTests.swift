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
    /// Asserts inserting an element increments `count`, 
    /// and `contains(_:)` returns true for that element.
    func testInsertOne() {
        var cuckooSet = CuckooSet<Double>()
        XCTAssertFalse(cuckooSet.contains(1.2))
        XCTAssertEqual(cuckooSet.count, 0)
        cuckooSet.insert(1.2)
        XCTAssertTrue(cuckooSet.contains(1.2))
        XCTAssertEqual(cuckooSet.count, 1)
    }

    /// Asserts the set treats `nil` and the binary `0` as different elements.
    func testNilDifferentFromZero() {
        var testSet = CuckooSet<UInt?>()
        XCTAssertEqual(testSet.count, 0, "expected count of 0 but found \(testSet.count)")
        XCTAssertTrue(testSet.insert(nil), "inserting first element (nil) failed")
        XCTAssertEqual(testSet.count, 1, "expected count of 1, but found \(testSet.count)")
        XCTAssertTrue(testSet.insert(0), "inserting second element (0) failed")
        XCTAssertEqual(testSet.count, 2, "expected count of 2 but found \(testSet.count)")
    }

    /// Asserts inserting the same object twice does not insert a duplicate and reports a failure.
    func testInsertDuplicate() {
        var testSet = CuckooSet<Bool?>()
        testSet.insert(true)
        XCTAssertTrue(testSet.contains(true))
        XCTAssertEqual(testSet.count, 1)
        XCTAssertFalse(testSet.insert(true))
        XCTAssertTrue(testSet.contains(true))
        XCTAssertEqual(testSet.count, 1)
    }

    /// Asserts insertions that require expansion still succeed losslessly.
    func testInsertMany() {
        var testSet = CuckooSet<Int>()
        var lastCount = 0
        var lastCapacity = testSet.capacity
        var expansionCount = 0
        for number in 1 ... 10_000 {
            // All numbers in this range are unique, so fail if an insertion fails
            XCTAssertTrue(testSet.insert(number), "insertion failed for number \(number)")

            // Keep track of the count to detect any unexpected jumps
            if testSet.count != lastCount + 1 {
                XCTFail("count jumped from \(lastCount) to \(testSet.count) at number \(number)")
                lastCount = testSet.count
            } else {
                lastCount += 1
            }

            // Track when and how often the set storage is expanded
            let newCapacity = testSet.capacity
            if newCapacity > lastCapacity { 
                print("set expanded to \(newCapacity) buckets for number \(number)") 
                expansionCount += 1
                lastCapacity = newCapacity
            }
        }
        let countErrorDescription = "expected count of 10,000, but found \(testSet.count)"
        XCTAssertEqual(testSet.count, 10_000, countErrorDescription)
        print("set expanded \(expansionCount) times")
    }

    func testRemove() {
        var cuckooSet: CuckooSet = ["test"]
        XCTAssertTrue(cuckooSet.contains("test"))
        XCTAssertEqual(cuckooSet.count, 1)
        cuckooSet.remove("test")
        XCTAssertFalse(cuckooSet.contains("false"))
        XCTAssertEqual(cuckooSet.count, 0)
    }
}