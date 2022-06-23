//
//  CuckooStorageTests.swift
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
