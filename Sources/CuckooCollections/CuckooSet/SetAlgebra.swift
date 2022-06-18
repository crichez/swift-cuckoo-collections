//
//  SetAlgebra.swift
//  CuckooSet
//
//  Created by Christopher Richez on January 18 2022
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
        insert(contentsOf: otherSet)
    }

    public func union(_ otherSet: Self) -> Self {
        var copy = self
        copy.formUnion(otherSet)
        return copy
    }

    public mutating func formIntersection(_ otherSet: Self) {
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
        // Keep the load factor of the hash table under 0.5
        if capacity < count * 2 { expand() }
        // Get the hashes and buckets for the new member
        let hash1 = primaryHash(of: newMember)
        let hash2 = secondaryHash(of: newMember)
        let bucket1 = bucket(for: hash1)
        let bucket2 = bucket(for: hash2)
        // Check for an existing member at both buckets
        for bucket in [bucket1, bucket2] {
            if let memberFound = buckets[bucket] {
                let memberFoundHash1 = primaryHash(of: memberFound)
                let memberFoundHash2 = secondaryHash(of: memberFound)
                if memberFoundHash1 == hash1 && memberFoundHash2 == hash2 {
                    return (inserted: false, memberAfterInsert: memberFound)
                }
            }
        }
        // If no existing member was found, check the primary bucket
        if buckets[bucket1] == nil {
            // If it's empty, assign the new member and increment count
            buckets[bucket1] = newMember
            count += 1
            return (inserted: true, memberAfterInsert: newMember)
        } else {
            // If it's full, prepare to bump its member
            var bumped = (member: newMember, bucket: bucket1)
            // Keep track of the number of consecutive bumps for this insertion
            var bumpCount = 0
            // Keep bumping until the method returns nil
            while let nextBump = bump(bucket: bumped.bucket, for: bumped.member) {
                // Expand and retry if we hit 20 consicutive bumps
                guard bumpCount < 20 else {
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
    }

    /// Removes the specified element from the set.
    @discardableResult
    public mutating func remove(_ member: Element) -> Element? {
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
