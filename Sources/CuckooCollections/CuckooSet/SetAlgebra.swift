//
//  SetAlgebra.swift
//  CuckooCollections
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

extension CuckooSet: SetAlgebra {
    
    // MARK: Comparison
    
    public func contains(_ member: Element) -> Bool {
        // Get the hashes and buckets for the new member
        let hash1 = primaryHash(of: member)
        let hash2 = secondaryHash(of: member)
        let bucket1 = bucket(for: hash1)
        let bucket2 = bucket(for: hash2)
        // Check both buckets
        for bucket in [bucket1, bucket2] {
            if let memberFound = buckets[bucket] {
                let foundHash1 = primaryHash(of: memberFound)
                let foundHash2 = secondaryHash(of: memberFound)
                if foundHash1 == hash1 && foundHash2 == hash2 {
                    return true
                }
            }
        }
        // If we havent found anything yet, return false
        return false
    }

    public func isSubset(of other: Self) -> Bool {
        for element in self where !other.contains(element) {
            return false
        }
        return true
    }

    public func isStrictSubset(of other: Self) -> Bool {
        guard self != other else { return false }
        return isSubset(of: other)
    }

    public func isSuperset(of other: Self) -> Bool {
        for element in other where !self.contains(element) {
            return false
        }
        return true
    }

    public func isStrictSuperset(of other: Self) -> Bool {
        guard self != other else { return false }
        return isSuperset(of: other)
    }

    public func isDisjoint(with other: Self) -> Bool {
        for element in self where other.contains(element) {
            return false
        }
        for element in other where self.contains(element) {
            return false
        }
        return true
    }
    
    // MARK: Algebra

    public mutating func formUnion(_ otherSet: Self) {
        copyOnWrite()
        insert(contentsOf: otherSet)
    }

    public func union(_ otherSet: Self) -> Self {
        var copy = self
        copy.formUnion(otherSet)
        return copy
    }

    public mutating func formIntersection(_ otherSet: Self) {
        copyOnWrite()
        for element in self where !otherSet.contains(element) {
            remove(element)
        }
    }

    public func intersection(_ otherSet: Self) -> Self {
        var copy = self
        copy.formIntersection(otherSet)
        return copy
    }

    public mutating func formSymmetricDifference(_ otherSet: Self) {
        copyOnWrite()
        for element in otherSet where !self.insert(element).inserted {
            remove(element)
        }
    }

    public func symmetricDifference(_ otherSet: Self) -> Self {
        var copy = self
        copy.formSymmetricDifference(otherSet)
        return copy
    }

    public mutating func subtract(_ otherSet: Self) {
        copyOnWrite()
        for element in otherSet {
            remove(element)
        }
    }

    public func subtracting(_ otherSet: Self) -> Self {
        var copy = self
        copy.subtract(otherSet)
        return copy
    }
    
    // MARK: Operations

    @discardableResult
    public mutating func insert(
        _ newMember: Element
    ) -> (inserted: Bool, memberAfterInsert: Element) {
        copyOnWrite()
        // Keep the load factor of the hash table under 0.5
        if capacity < count * 2 { expand() }
        
        // Resolve the primary bucket of the new member.
        let newHash1 = primaryHash(of: newMember)
        let bucket1Index = bucket(for: newHash1)
        let bucket1 = buckets.getPointerToBucket(bucket1Index)
        
        // A memo for the secondary hash of the new member.
        var newHash2 = UInt64?.none
        
        // Hash memos for the member at the primary bucket of the new member.
        var current1Hash1 = UInt64?.none
        var current1Hash2 = UInt64?.none
        
        // Check the contents of the primary bucket of the new member.
        if let currentMember = bucket1.pointee {
            // Check the primary hash of the member currently at the new member's primary bucket.
            current1Hash1 = primaryHash(of: currentMember)
            if current1Hash1 == newHash1 {
                // If the primary hashes match, also check the secondary hashes.
                current1Hash2 = secondaryHash(of: currentMember)
                newHash2 = secondaryHash(of: newMember)
                if current1Hash2 == newHash2 {
                    // If the secondary hash also matches, this is the same member.
                    return (inserted: false, memberAfterInsert: currentMember)
                }
            }
        } else {
            // The primary bucket is empty or didn't match, but we must still check the secondary.
            // We do no work here, control flow moves to the secondary bucket.
        }
        
        // Memos for the hashes of the member at the secondary bucket of the new member.
        var current2Hash1 = UInt64?.none
        var current2Hash2 = UInt64?.none
        
        // Compute the location of the secondary bucket.
        if newHash2 == nil { newHash2 = secondaryHash(of: newMember) }
        let bucket2Index = bucket(for: newHash2!)
        let bucket2 = buckets.getPointerToBucket(bucket2Index)
        
        // Check the contents of the secondary bucket.
        if let currentMember = bucket2.pointee {
            // Check the primary hash of the member at bucket 2.
            current2Hash1 = primaryHash(of: currentMember)
            if current2Hash1 == newHash1 {
                // If the primary hashes match, also check the secondary hashes.
                current2Hash2 = secondaryHash(of: currentMember)
                if current2Hash2 == newHash2! {
                    // If the secondary hash also matches, this is the same member.
                    return (inserted: false, memberAfterInsert: currentMember)
                }
            }
        } else {
            // The secondary bucket is empty or didn't match, so we move to the insert.
        }
        
        // Check for an empty bucket and insert the new member directly.
        if bucket1.pointee == nil {
            bucket1.pointee = newMember
            count += 1
            return (inserted: true, memberAfterInsert: newMember)
        } else if bucket2.pointee == nil {
            bucket2.pointee = newMember
            count += 1
            return (inserted: true, memberAfterInsert: newMember)
        } else {
            // If both buckets are full, we have to bump the primary bucket.
        }
        
        var bumped = (member: newMember, bucket: bucket1Index)
        // Keep track of the number of consecutive bumps for this insertion
        var bumpCount = 0
        // Keep bumping until the method returns nil
        while let nextBump = bump(bucketIndex: bumped.bucket, for: bumped.member) {
            // Expand and retry if we hit 20 consicutive bumps
            guard bumpCount < count / 10 else {
                expand()
                return insert(nextBump.member)
            }
            bumpCount += 1
            bumped = nextBump
        }
        // Once we are done bumping, increment the count and report success
        count += 1
        return (inserted: true, memberAfterInsert: newMember)
    }

    /// Removes the specified element from the set.
    @discardableResult
    public mutating func remove(_ member: Element) -> Element? {
        copyOnWrite()
        // Get the hashes and buckets for the member to remove
        let hash1 = primaryHash(of: member)
        let bucket1 = bucket(for: hash1)
        let hash2 = secondaryHash(of: member)
        let bucket2 = bucket(for: hash2)
        // Check both buckets
        for bucket in [bucket1, bucket2] {
            if let memberFound = buckets[bucket] {
                let foundHash1 = primaryHash(of: memberFound)
                let foundHash2 = secondaryHash(of: memberFound)
                if foundHash1 == hash1 && foundHash2 == hash2 {
                    buckets[bucket] = nil
                    count -= 1
                    return member
                }
            } 
        }
        // If no matches were found, report the member was not removed
        return nil
    }

    @discardableResult
    public mutating func update(with newMember: Element) -> Element? {
        return insert(newMember).memberAfterInsert
    }
    
    /// Initializes an empty set with a default capacity of 32 (16 members).
    ///
    /// - Note: `CuckooSet` doubles its capacity when `count` reaches roughly half of `capacity`.
    /// When allocating a set to store a known number of members,
    /// request a capacity of at least double the known number of members.
    public init() {
        self.init(capacity: 32)
    }
}
