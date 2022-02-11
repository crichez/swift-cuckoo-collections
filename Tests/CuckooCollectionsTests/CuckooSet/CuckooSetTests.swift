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
        XCTAssertTrue(testSet.insert(nil).inserted, "inserting first element (nil) failed")
        XCTAssertEqual(testSet.count, 1, "expected count of 1, but found \(testSet.count)")
        XCTAssertTrue(testSet.insert(0).inserted, "inserting second element (0) failed")
        XCTAssertEqual(testSet.count, 2, "expected count of 2 but found \(testSet.count)")
    }

    /// Asserts inserting the same object twice does not insert a duplicate and reports a failure.
    func testInsertDuplicate() {
        var testSet = CuckooSet<Bool?>()
        testSet.insert(true)
        XCTAssertTrue(testSet.contains(true))
        XCTAssertEqual(testSet.count, 1)
        XCTAssertFalse(testSet.insert(true).inserted)
        XCTAssertTrue(testSet.contains(true))
        XCTAssertEqual(testSet.count, 1)
    }

    /// Asserts insertions that require expansion still succeed losslessly.
    /// The sequence of 1 to 10_000 also contains some hash collisions that need to be handled.
    /// The subsequent deletions are in this test to avoid duplicating work.
    func testInsertAndRemoveMany() {
        var testSet = CuckooSet<Int>()
        var lastCount = 0
        var lastCapacity = testSet.capacity
        var expansionCount = 0
        for number in 1 ... 10_000 {
            // All numbers in this range are unique, so fail if an insertion fails
            XCTAssertTrue(testSet.insert(number).inserted, "insertion failed for number \(number)")
            XCTAssertTrue(testSet.contains(number), "number \(number) failed contains check")

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

        for number in 1 ... 10_000 {
            testSet.remove(number)
            XCTAssertFalse(testSet.contains(number))
            if testSet.count != lastCount - 1 {
                XCTFail("expected count \(lastCount - 1) after removing \(number) but found \(testSet.count)")
                lastCount = testSet.count
            } else {
                lastCount -= 1
            }
        }
    }

    func testDebugDescription() {
        let testSet: CuckooSet<String> = ["this", "is", "a", "test"]
        let expectedDescription = """
        CuckooSet<String>([
            this,
            test,
            a,
            is,
        ])
        """
        XCTAssertEqual(testSet.debugDescription, expectedDescription)
    }
    
    /// Asserts `CuckooSet.Iterator` returns all members previously inserted into the set
    /// before returning `nil`.
    func testIteratorReturnsAllMembers() {
        let testSet: CuckooSet<Int> = [0, 1, 2, 3, 4, 5]
        var testSetMembers: [Int] = []
        for member in testSet {
            testSetMembers.append(member)
        }
        XCTAssertEqual(testSet.count, 6)
        XCTAssertEqual(testSetMembers.count, 6)
        for member in testSetMembers {
            XCTAssertTrue(testSet.contains(member))
        }
    }
    
    /// Measures the performance of the `insert(_:)` method.
    ///
    /// This method declares an amortized complexity of `O(1)`.
    /// An individual operation may report `O(n)` complexity if hash table expansion is required.
    func testInsertPerformance() {
        // Get a list of 1000 unique values
        var uniqueMembers = CuckooSet<Int>(capacity: 2048)
        for _ in 0 ... 1000 {
            var random = Int.random(in: .min ... .max)
            while uniqueMembers.contains(random) {
                random = .random(in: .min ... .max)
            }
            uniqueMembers.insert(random)
        }
        
        // Copy each element into a ContiguousArray
        let uniqueMemberList = ContiguousArray(uniqueMembers)
        // Get an iterator for that array to avoid overhead of iterating over empty buckets
        var iterator = uniqueMemberList.makeIterator()
        
        // Initialize an empty set with a capacity of 32 and set up the test loop
        var testSet: CuckooSet<Int> = []
        let options = XCTMeasureOptions()
        options.iterationCount = 1000
        
        // Insert 1000 unique members into the set
        measure(metrics: [XCTClockMetric()], options: options) {
            testSet.insert(iterator.next()!)
        }
    }
    
    /// Measures the performance of the `contains(_:)` method.
    ///
    /// This method declares a complexity of `O(n)`
    func testContainsPerformance() {
        // Get a list of 1000 unique values
        var uniqueMembers: CuckooSet<Int> = []
        for _ in 0 ... 1000 {
            var random = Int.random(in: .min ... .max)
            while uniqueMembers.contains(random) {
                random = .random(in: .min ... .max)
            }
            uniqueMembers.insert(random)
        }
        let uniqueMemberList = ContiguousArray(uniqueMembers)
        var iterator = uniqueMemberList.makeIterator()
        let options = XCTMeasureOptions()
        options.iterationCount = 1000
        measure(metrics: [XCTClockMetric()], options: options) {
            let _ = uniqueMembers.contains(iterator.next()!)
        }
    }
}
