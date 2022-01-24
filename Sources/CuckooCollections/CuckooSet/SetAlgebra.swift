//
//  SetAlgebra.swift
//  CuckooSet
//
//  Created by Christopher Richez on January 18 2022
//

extension CuckooSet: SetAlgebra {
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

    @discardableResult
    public mutating func insert(
        _ newMember: Element
    ) -> (inserted: Bool, memberAfterInsert: Element) {
        // Keep the load factor of the table under 0.5
        if capacity < count * 2 { expand() }

        // Get the primary hash and bucket for the new element
        let primaryHash = primaryHash(of: newMember)
        let primaryBucket = bucket(for: primaryHash)
        // Optionally, get the reported hash and element that occupies that bucket
        let hashOfPrimaryElement = contents(ofBucket: primaryBucket)?.hash
        let elementAtPrimaryBucket = contents(ofBucket: primaryBucket)?.element

        // Get the secondary hash and bucket for the new element
        let secondaryHash = secondaryHash(of: newMember)
        let secondaryBucket = bucket(for: secondaryHash)
        // Optionally, get the reported hash and element that occupies that bucket
        let hashOfSecondaryElement = contents(ofBucket: secondaryBucket)?.hash
        let elementAtSecondaryBucket = contents(ofBucket: secondaryBucket)?.element

        // Check whether an element exists at the primary bucket
        // Check whether that element has the same primary hash as the new element
        if let existingElement = elementAtPrimaryBucket, hashOfPrimaryElement == primaryHash {
            /// The primary hash of the element found at the primary bucket.
            let hash1 = self.primaryHash(of: existingElement)
            /// The secondary hash of the element found at the primary bucket.
            let hash2 = self.secondaryHash(of: existingElement)
            // Check whether both hashes of the existing element match those of the new element
            if hash1 == primaryHash && hash2 == secondaryHash {
                // If so, these are likely the same element
                return (inserted: false, memberAfterInsert: existingElement)
            } else {
                // If not, these are not the same element
                /// Whether the element at the primary bucket is hashed at its primary location.
                let isAtPrimaryLocation = hash1 == hashOfPrimaryElement
                // Bump the existing element to its alternative bucket
                count += 1
                return bump(bucket: primaryBucket, for: newMember, atPrimaryLocation: isAtPrimaryLocation) 
            }
        // Check whether an element exists at the secondary bucket
        // Check whether that element has the same secondary hash as the new element
        } else if let existingElement = elementAtSecondaryBucket, hashOfSecondaryElement == secondaryHash {
            /// The primary hash of the element found at the secondary bucket.
            let hash1 = self.primaryHash(of: existingElement)
            /// The secondary hash of the element found at the secondary bucket.
            let hash2 = self.secondaryHash(of: existingElement)
            // Check whether both hashes of the existing element match those of the new element
            if hash1 == primaryHash && hash2 == secondaryHash {
                // If so, these are likely the same element
                return (inserted: false, memberAfterInsert: existingElement)
            } else {
                // If not, these are not the same element
                /// Whether the element at the secondary bucket is hashed at its primary location
                let isAtPrimaryLocation = hash1 == hashOfSecondaryElement
                // Bump the existing element to its alternative bucket
                count += 1
                return bump(bucket: secondaryBucket, for: newMember, atPrimaryLocation: isAtPrimaryLocation)
            }
        // If neither of the previous patterns matched, the element does not already exist
        } else {
            // Check if the primary bucket is free
            if hashOfPrimaryElement == nil {
                // If it is, insert it directly
                buckets[primaryBucket] = .some(primaryHash, newMember)
                count += 1
                return (inserted: true, memberAfterInsert: newMember)
            } else {
                // If it is not, request a bump and insert it later
                count += 1
                return bump(bucket: primaryBucket, for: newMember, atPrimaryLocation: true)
            }
        }
    }

    /// Removes the specified element from the set.
    @discardableResult
    public mutating func remove(_ member: Element) -> Element? {
        let hash1 = primaryHash(of: member)
        let bucket1 = bucket(for: hash1)
        let hash2 = secondaryHash(of: member)
        let bucket2 = bucket(for: hash2)

        if let (_, memberFound) = contents(ofBucket: bucket1) {
            let foundHash1 = primaryHash(of: memberFound)
            let foundHash2 = secondaryHash(of: memberFound)
            if foundHash1 == hash1 && foundHash2 == hash2 {
                buckets[bucket1] = .none
                count -= 1
                return member
            }
        } 
        if let (_, memberFound) = contents(ofBucket: bucket2) {
            let foundHash1 = primaryHash(of: memberFound)
            let foundHash2 = secondaryHash(of: memberFound)
            if foundHash1 == hash1 && foundHash2 == hash2 {
                buckets[bucket2] = .none
                count -= 1
                return member
            }
        }
        return nil
    }

    @discardableResult
    public mutating func update(with newMember: Element) -> Element? {
        return insert(newMember).memberAfterInsert
    }
}