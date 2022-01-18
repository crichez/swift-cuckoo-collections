//
//  ComparisonOperationsTests.swift
//
//
//  Created by Christopher Richez on January 10 2022
//

import CuckooCollections
import XCTest

/// The test case for the methods contained in 
/// the `Sources/CuckooCollections/CuckooSet/ComparisonOperations.swift` file
class ComparisonOperationsTests: XCTestCase {
    /// Asserts two sets with different capacities that contain the same elements should be equal.
    func testEqualityWithDifferentCapacity() {
        var set1 = CuckooSet<Double>(capacity: 16)
        var set2 = CuckooSet<Double>(capacity: 32)

        set1.insert(1.295)
        XCTAssertEqual(set1.capacity, 16, "set1 expanded, use different inputs")
        XCTAssertNotEqual(set1, set2, "sets reported equality with different elements")
        set2.insert(1.295)
        XCTAssertEqual(set2.capacity, 32, "set2 expanded, use different inputs")
        XCTAssertEqual(set1, set2)

        set1.insert(-0.999)
        XCTAssertEqual(set1.capacity, 16, "set1 expanded, use different inputs")
        XCTAssertNotEqual(set1, set2, "sets reported equality with different elements")
        set2.insert(-0.999)
        XCTAssertEqual(set2.capacity, 32, "set2 expanded, use different inputs")
        XCTAssertEqual(set1, set2)

        set1.insert(9.333)
        XCTAssertEqual(set1.capacity, 16, "set1 expanded, use different inputs")
        XCTAssertNotEqual(set1, set2, "sets reported equality with different elements")
        set2.insert(9.333)
        XCTAssertEqual(set2.capacity, 32, "set2 expanded, use different inputs")
        XCTAssertEqual(set1, set2)
    }

    /// Asserts two sets with identical capacities that contain the same elements should be equal.
    func testEqualityWithSameCapacity() throws {
        var set1 = CuckooSet<Double>(capacity: 32)
        var set2 = CuckooSet<Double>(capacity: 32)

        set1.insert(1.295)
        XCTAssertEqual(set1.capacity, 32, "set1 expanded, use different inputs")
        XCTAssertNotEqual(set1, set2, "sets reported equality with different elements")
        set2.insert(1.295)
        XCTAssertEqual(set2.capacity, 32, "set2 expanded, use different inputs")
        XCTAssertEqual(set1, set2)

        set1.insert(-0.999)
        XCTAssertEqual(set1.capacity, 32, "set1 expanded, use different inputs")
        XCTAssertNotEqual(set1, set2, "sets reported equality with different elements")
        set2.insert(-0.999)
        XCTAssertEqual(set2.capacity, 32, "set2 expanded, use different inputs")
        XCTAssertEqual(set1, set2)

        set1.insert(9.333)
        XCTAssertEqual(set1.capacity, 32, "set1 expanded, use different inputs")
        XCTAssertNotEqual(set1, set2, "sets reported equality with different elements")
        set2.insert(9.333)
        XCTAssertEqual(set2.capacity, 32, "set2 expanded, use different inputs")
        XCTAssertEqual(set1, set2)
    }

    /// Asserts the presence of `nil` optionals in a set affects its equality to another set.
    func testEqualityWithNilOptionals() {
        let set1: CuckooSet<String?> = ["this", "is", "a", "test"]
        let set2: CuckooSet<String?> = [nil, "this", "is", "a", "test"]
        XCTAssertNotEqual(set1, set2, "different sets unexpectedly reported equality")
    }

    /// Asserts a set with only some elements in common with another is a subset of that other set.
    func testSubset() throws {
        let superset: CuckooSet<Float?> = [nil, 0.0, -9.091, 0.887]
        let subset: CuckooSet<Float?> = [0.0, -9.091, 0.887]
        XCTAssertTrue(subset.isSubset(of: superset), "incorrect subset evaluation")
    }

    /// Asserts two identical sets are subsets of one another.
    func testSubsetIfEqual() throws {
        let superset: CuckooSet<Float?> = [nil, 0.0, -9.091, 0.887]
        let subset = superset
        XCTAssertTrue(subset.isSubset(of: superset), "subset evaluation failed")
        XCTAssertTrue(superset.isSubset(of: subset), "subset evaluation failed")
    }

    /// Asserts a set with only some elements in common with another is a strict subset of that other set.
    func testStrictSubset() throws {
        let superset: CuckooSet<Float?> = [nil, 0.0, -9.091, 0.887]
        let subset: CuckooSet<Float?> = [0.0, -9.091, 0.887]
        #warning("this test is failing if the only difference between the sets is a nil")
        #warning("this probably has to do with the hash function, need to investigate")
        XCTAssertTrue(subset.isStrictSubset(of: superset), "incorrect strict subset evaluation")
    }

    /// Asserts two identical sets are not strict subsets of one another.
    func testNotStrictSubsetIfEqual() throws {
        let superset: CuckooSet<Float?> = [nil, 0.0, -9.091, 0.887]
        let subset = superset
        XCTAssertFalse(subset.isStrictSubset(of: superset), "strict subset evaluation failed")
    }

    /// Asserts a set with all of the elements of another and more is a superset of that other set.
    func testSuperset() throws {
        let superset: CuckooSet<Float?> = [nil, 0.0, -9.091, 0.887]
        let subset: CuckooSet<Float?> = [0.0, -9.091, 0.887]
        XCTAssertTrue(superset.isSuperset(of: subset), "superset evaluation failed")
    }

    /// Asserts two identical sets are supersets of one another.
    func testSupersetIfEqual() throws {
        let superset: CuckooSet<Float?> = [nil, 0.0, -9.091, 0.887]
        let subset: CuckooSet<Float?> = superset
        XCTAssertTrue(superset.isSuperset(of: subset), "superset evaluation failed")
        XCTAssertTrue(subset.isSuperset(of: superset), "superset evaluation failed")
    }

    /// Asserts a set with all of the elements of another and more is a struct superset of that other set.
    func testStrictSuperset() throws {
        let superset: CuckooSet<Float?> = [nil, 0.0, -9.091, 0.887]
        let subset: CuckooSet<Float?> = [0.0, -9.091, 0.887]
        #warning("this test is failing if the only difference between the sets is a nil")
        #warning("this probably has to do with the hash function, need to investigate")
        XCTAssertTrue(superset.isStrictSuperset(of: subset), "strict superset evaluation failed")
    }

    /// Asserts two identical sets are not strict supersets of one another.
    func testNotStrictSupersetIfEqual() throws {
        let superset: CuckooSet<Float?> = [nil, 0.0, -9.091, 0.887]
        let subset: CuckooSet<Float?> = superset
        XCTAssertFalse(superset.isStrictSuperset(of: subset), "strict superset evaluation failed")
    }

    /// Asserts two sets with no elements in common are disjoint from one another.
    func testDisjoint() throws {
        let set1: CuckooSet<String> = ["one", "two", "three"]
        let set2: CuckooSet<String> = ["four", "five", "six"]
        XCTAssertTrue(set1.isDisjoint(with: set2), "disjoint evaluation failed")
    }
}