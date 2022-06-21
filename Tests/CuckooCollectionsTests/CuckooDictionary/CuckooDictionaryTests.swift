//
//  CuckooDictionaryTests.swift
//  CuckooDictionaryTests
//
//  Created by Christopher Richez on January 24 2022
//

import CuckooCollections
import XCTest

/// The test case for the `CuckooDictionary` API.
class CuckooDictionaryTests: XCTestCase {
    /// Asserts the `insert(key:value:)` method:
    /// * Inserts new key-value pairs
    /// * Returns `true` when a new key-value pair was inserted
    /// * Increments `count` when a new key is inserted
    /// * Does not update values for existing keys
    /// * Returns `false` when inserting an existing key-value pair
    /// * Does not increment count when an existing key is inserted
    func testInsertOne() throws {
        // Start with an empty dictionary
        var testDict: CuckooDictionary<String, Int> = [:]
        // Assert inserting a new key returns true
        XCTAssertTrue(testDict.insert(key: "one", value: 1), "valid insertion reported failure")
        // Assert the correct value is retrieved for the new key
        XCTAssertEqual(testDict["one"], 1, "valid insertion failed")
        // Assert count was incremented by one
        XCTAssertEqual(testDict.count, 1)
        // Assert trying to insert a different value for the same key returns false
        XCTAssertFalse(testDict.insert(key: "one", value: 2))
        // Assert the value was not changed
        XCTAssertEqual(testDict["one"], 1)
        // Assert count was not incremented
        XCTAssertEqual(testDict.count, 1)
    }

    /// Asserts the `remove(key:)` method:
    /// * Removes the specified key
    /// * Returns `true` when a key is removed
    /// * Decrements `count` when a key is removed
    /// * Returns `false` when a non-existing key is removed
    /// * Does not decrement `count` when a non-existing key is removed
    func testRemoveOne() throws {
        // Start with a dictionary with one element
        var testDict: CuckooDictionary<Int, String> = [1: "one"]
        // Assert removing an existing key returns true
        XCTAssertTrue(testDict.remove(key: 1), "valid removal reported failure")
        // Assert the key was removed
        XCTAssertNil(testDict[1], "key not removed after removal reported success")
        // Assert count was decremented
        XCTAssertEqual(testDict.count, 0, "count not decremented after removal reported success")
        // Assert removing a non-existing key returns false
        XCTAssertFalse(testDict.remove(key: 1), "invalid removal reported success")
        // Assert removing a non-existing key does not decrement the count
        XCTAssertEqual(testDict.count, 0, "invalid removal changed count to \(testDict.count)")
    }

    /// Asserts the `updateValue(forKey:with:)` method:
    /// * Updates the value for an existing key
    /// * Returns false when updating existing keys
    /// * Does not increment `count` when updating a value
    /// * Inserts new key-value pairs when the key does not exist
    /// * Returns `true` when key-value pair was inserted
    /// * Increments `count` when a key-value pair was inserted
    func testUpdateOne() throws {
        // Start with a dictionary with one pair
        var testDict: CuckooDictionary<Double, Bool> = [1.295: false]
        // Assert updating an existing key returns false
        XCTAssertFalse(testDict.updateValue(forKey: 1.295, with: true))
        // Assert the key was actually updated
        XCTAssertEqual(testDict[1.295], true)
        // Assert the count has not changed
        XCTAssertEqual(testDict.count, 1)
        // Assert updating a non-existing key returns true
        XCTAssertTrue(testDict.updateValue(forKey: 1.296, with: true))
        // Assert the key was inserted
        XCTAssertEqual(testDict[1.296], true)
        // Assert count was incremented
        XCTAssertEqual(testDict.count, 2)
    }


    /// Asserts a key-value pair inserted using the mutable subscript is retrievable
    /// using the subscript, the `keys` view, and is reflected in the `count`.
    func testSubscriptInsertOne() throws {
        var testDict: CuckooDictionary<String, Double> = [:]
        testDict["test"] = 1.295
        XCTAssertEqual(testDict["test"], 1.295)
        XCTAssertNil(testDict["hello"])
        XCTAssertEqual(testDict.count, 1)
    }

    /// Asserts removing an existing key-value using the mutable subscript is reflected by
    /// `contains(_:)` checks, subscript retrieval, and `count`.
    func testSubscriptRemoveOne() throws {
        var testDict: CuckooDictionary<String, String> = ["test": "yes"]
        testDict["test"] = nil
        XCTAssertNil(testDict["test"])
        XCTAssertEqual(testDict.count, 0)
    }

    /// Asserts removing a key from an empty dictionary performs no work.
    func testSubscriptRemoveFromEmptyDict() throws {
        var testDict: CuckooDictionary<Int, Bool> = [:]
        testDict[19] = nil
        XCTAssertEqual(testDict.count, 0)
        XCTAssertNil(testDict[19])
    }

    /// Asserts inserting many key-value pairs adequately expands the dictionary.
    func testInsertMany() throws {
        // Initialize a dictionary with the default capacity
        var testDict: CuckooDictionary<Int, Bool> = [:]
        // Store every key in a separate set to ensure each inserted key is unique
        var insertedKeys = CuckooSet<Int>(capacity: 20_000)
        // Keep track of the count and capacity of the dictionary over time
        var lastCount = 0
        var lastCapacity = testDict.capacity
        // Insert 10,000 unique key-value pairs
        for _ in 1 ... 100_000 {
            // Ensure the next key is unique before inserting it
            var randomKey = Int.random(in: .min ... .max)
            while insertedKeys.contains(randomKey) {
                randomKey = .random(in: .min ... .max)
            }
            insertedKeys.insert(randomKey)
            // Insert the random key with a true value
            testDict[randomKey] = true
            // Assert the key-value pair was succesfully added
            XCTAssertEqual(testDict[randomKey], true, "key \(randomKey) not inserted")
            // Assert count was incremented by one
            XCTAssertEqual(testDict.count, lastCount + 1, "unexpected count after \(randomKey)") 
            lastCount = testDict.count
            // Check for hash table expansions
            if testDict.capacity > lastCapacity {
                print("dictionary expanded to \(testDict.capacity) for key \(randomKey)")
                lastCapacity = testDict.capacity
            }
        }
    }

    /// Asserts the dictionary iterator returns all expected elements.
    func testIterator() {
        let dict: CuckooDictionary = [0: 0, 1: 1, 2: 2]
        var timesFoundZero = 0
        var timesFoundOne = 0
        var timesFoundTwo = 0
        for (key, value) in dict {
            if key == 0 && value == 0 {
                timesFoundZero += 1
            } else if key == 1 && value == 1 {
                timesFoundOne += 1
            } else if key == 2 && value == 2 {
                timesFoundTwo += 1
            }
        }
        XCTAssertEqual(timesFoundZero, 1)
        XCTAssertEqual(timesFoundOne, 1)
        XCTAssertEqual(timesFoundTwo, 1)
    }
}