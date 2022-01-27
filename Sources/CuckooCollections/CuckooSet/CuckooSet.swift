//
//  CuckooSet.swift
//  CuckooSet
//
//  Created by Christopher Richez on January 5th, 2021
//

import FowlerNollVo

/// A set that uses a cuckoo hashing algorithm to insert each member.
///
/// `CuckooSet` conforms to `SetAlgebra` and exposes the same API as the Swift standard
/// library `Set`, but requires that `Element` conform to `FNVHashable`.
public struct CuckooSet<Element: FNVHashable> {
    /// An array of `Bucket` cases used as storage for the set.
    var buckets: [Element?]

    /// Initializes an empty `CuckooSet` with the provided capacity.
    ///
    /// - Parameter capacity: the number of buckets in the set hash table, defaults to 32
    ///
    /// - Note: Unlike `Set`, `CuckooSet` doubles its capacity when `count` reaches half of
    /// `capacity`. When allocating a set to store a known number of members, request
    /// a capacity of at least double the number of members.
    public init(capacity: Int = 32) {
        self.buckets = [Element?](repeating: nil, count: capacity)
        self.count = 0
    }

    /// Initializes an empty set with a default capacity of 32 (16 members).
    public init() {
        self.init(capacity: 32)
    }

    /// The current capacity of the set.
    public var capacity: Int {
        buckets.count
    }

    /// The number of members stored in this set.
    public var count: Int

    /// Computes the primary hash of the provided element.
    ///
    /// The primary hash uses the FNV-1a hash function with a 64-bit digest.
    ///
    /// - Parameter member: the set member to hash
    ///
    /// - Returns: The primary hash function digest as an `UInt64`.
    func primaryHash(of member: Element) -> UInt64 {
        var hasher = FNV1aHasher<UInt64>()
        hasher.combine(member)
        return hasher.digest
    }

    /// Computes the secondary hash of the provided element.
    ///
    /// The secondary hash uses the FNV-1 hash function with a 64-bit digest.
    ///
    /// - Parameter member: the set member to hash
    ///
    /// - Returns: The secondary hash function digest as an `UInt64`.
    func secondaryHash(of member: Element) -> UInt64 {
        var hasher = FNV1Hasher<UInt64>()
        hasher.combine(member)
        return hasher.digest
    }
    
    /// Computes the bucket the provided hash should be stored in.
    ///
    /// - Parameter hash: the primary or secondary hash of a set member
    ///
    /// - Returns: The bucket the element with the provided hash should be stored in.
    func bucket(for hash: UInt64) -> Int {
        Int(hash % UInt64(capacity))
    }

    /// Doubles the number of buckets in the set, then re-inserts every element.
    mutating func expand() {
        var expandedSet = CuckooSet<Element>(capacity: capacity * 2)
        for member in self {
            expandedSet.insert(member)
        }
        self = expandedSet
    }

    /// Moves the provided member into the specified bucket, 
    /// and optionally returns the bumped element.
    ///
    /// - Parameters:
    ///     - bucket: the bucket to clear and insert the new member into
    ///     - newMember: the new member to insert at the specified bucket
    ///
    /// - Returns:
    /// Returns `nil` if the new member and bumped member were assigned to a bucket.
    /// If the alternative bucket for the bumped member is full, 
    /// returns a tuple containing the bumped member and its alternative bucket.
    mutating func bump(bucket: Int, for newMember: Element) -> (member: Element, bucket: Int)? {
        // Fetch the current contents of the bucket
        guard let bumpedMember = buckets[bucket] else {
            fatalError("requested a bump from an empty bucket")
        }
        // Overwrite the bucket with the new element
        buckets[bucket] = newMember
        // Get the new bucket of the bumped member
        let hash1 = primaryHash(of: bumpedMember)
        let hash2 = secondaryHash(of: bumpedMember)
        let bucket1 = self.bucket(for: hash1)
        let bucket2 = self.bucket(for: hash2)
        let isAtBucket1 = bucket1 == bucket
        let newBucket = isAtBucket1 ? bucket2 : bucket1
        // Check whether the new bucket is occupied
        if buckets[newBucket] == nil {
            buckets[newBucket] = bumpedMember
            return nil
        } else {
            return (bumpedMember, newBucket)
        }
    }

    /// Inserts each element of the provided sequence into the set.
    ///
    /// This method is equivalent to calling `insert(_:)` for each element in `newElements`.
    public mutating func insert<S>(contentsOf newElements: S) 
    where S : Sequence, S.Element == Element {
        for element in newElements {
            insert(element)
        }
    }

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

    /// Removes all elements in the set.
    ///
    /// This method removes all elements by overwriting the set's storage.
    public mutating func removeAll() {
        buckets = [Element?](repeating: nil, count: capacity)
    }
}

extension CuckooSet: Sequence {
    public func makeIterator() -> IndexingIterator<[Element]> {
        buckets.compactMap { $0 }.makeIterator()
    }
}

extension CuckooSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        var cuckooSet = CuckooSet<Element>()
        for element in elements {
            cuckooSet.insert(element)
        }
        self = cuckooSet
    }

    public init(_ array: [Element]) {
        var cuckooSet = CuckooSet<Element>(capacity: array.count * 2)
        cuckooSet.insert(contentsOf: array)
        self = cuckooSet
    }
}

extension CuckooSet where Element : Hashable {
    public init(_ otherSet: Set<Element>) {
        var cuckooSet = CuckooSet<Element>(capacity: otherSet.count * 2)
        cuckooSet.insert(contentsOf: otherSet)
        self = cuckooSet
    }
}

extension CuckooSet: CustomDebugStringConvertible {
    public var debugDescription: String {
        var description = "CuckooSet<\(Element.self)>([\n"
        for element in self {
            description.append("    \(element),\n")
        }
        description.append("])")
        return description
    }
}

extension CuckooSet: FNVHashable, Equatable {
    public func hash<Hasher>(into hasher: inout Hasher) where Hasher : FNVHasher {
        for element in self {
            hasher.combine(element)
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        var lhsHasher = FNV1aHasher<UInt64>()
        var rhsHasher = FNV1aHasher<UInt64>()
        lhs.hash(into: &lhsHasher)
        rhs.hash(into: &rhsHasher)
        return lhsHasher.digest == rhsHasher.digest
    }
}
