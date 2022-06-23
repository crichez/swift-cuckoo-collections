//
//  SetAlgebraTests.swift
//  CuckooCollectionsTests
//
//  Copyright 2022 Christopher Richez
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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