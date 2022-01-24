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
    /// A value that contains the state of a hash table bucket.
    enum Bucket {
        /// The bucket is empty.
        case none

        /// The bucket contains a set member.
        ///
        /// The value includes the assigned hash value of the member and the member itself.
        case some(UInt64, Element)
    }

    /// An array of `Bucket` cases used as storage for the set.
    var buckets: [Bucket]

    /// Initializes an empty `CuckooSet` with the provided capacity.
    ///
    /// - Parameter capacity: the number of buckets in the set hash table, defaults to 32
    ///
    /// - Note: Unlike `Set`, `CuckooSet` doubles its capacity when `count` reaches half of
    /// `capacity`. When allocating a set to store a known number of members, request
    /// a capacity of at least double the number of members.
    public init(capacity: Int = 32) {
        self.buckets = [Bucket](repeating: .none, count: capacity)
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

    /// Retrieves the contents of the specified bucket.
    ///
    /// - bucket: the index of the hash table bucket to retrieve the contents of
    ///
    /// - Returns: A tuple where `hash` is either the primary or secondary hash 
    /// of the stored element, and `element` is the stored element itself. If the bucket
    /// is empty, returns `nil`.
    func contents(ofBucket bucket: Int) -> (hash: UInt64, element: Element)? {
        guard bucket < capacity else { fatalError("tried to fetch a bucket out of bounds") }
        switch buckets[bucket] {
        case .none:
            return nil
        case .some(let hash, let element): 
            return (hash: hash, element: element)
        }
    }

    /// Doubles the number of buckets in the set, then re-inserts every element.
    mutating func expand() {
        var expandedSet = CuckooSet<Element>(capacity: capacity * 2)
        for member in self {
            expandedSet.insert(member)
        }
        self = expandedSet
    }

    /// Clears the specified occupied bucket and inserts a new member in its place.
    ///
    /// This method reorganizes the hash table to guarantee the new member can be stored,
    /// and may call itself recursively up to 20 times before expanding and re-hashing.
    ///
    /// - Parameters:
    ///     - bucket: the bucket to clear and insert the new member into
    ///     - newMember: the new member to insert at the specified bucket
    ///     - atPrimaryLocation: whether the new member is being inserted at its primary location
    ///     - iteration: the number of times `bump` was called for a single insertion
    ///
    /// - Returns: A tuple that is the result of calling `insert(_:)` after clearing the bucket.
    mutating func bump(
        bucket: Int, 
        for newMember: Element, 
        atPrimaryLocation: Bool, 
        iteration: Int = 0
    ) -> (inserted: Bool, memberAfterInsert: Element) {
        // At iteration 20 we are probably in a loop, 
        // so expand the set's storage to reduce the collision rate
        guard iteration < 20 else { expand(); return insert(newMember) }

        // Fetch the current contents of the bucket
        guard let (hash, element) = contents(ofBucket: bucket) else {
            fatalError("requested a bump from an empty bucket")
        }

        // Overwrite it with the new element
        let newHash = atPrimaryLocation ? primaryHash(of: newMember) : secondaryHash(of: newMember)
        buckets[bucket] = .some(newHash, newMember)

        // Find out if the bumped element is at its primary or secondary bucket
        let primaryHash = primaryHash(of: element)
        let secondaryHash = secondaryHash(of: element)
        let bumpToSecondary = hash == primaryHash
        let newBumpedHash = bumpToSecondary ? secondaryHash : primaryHash

        // Move the element to its alternative bucket
        let destinationBucket = self.bucket(for: newBumpedHash)
        if contents(ofBucket: destinationBucket) == nil {
            // If the secondary location is empty, insert it directly
            buckets[destinationBucket] = .some(newBumpedHash, element)
            return (true, newMember)
        } else {
            // If the secondary location if full, request a bump
            return bump(
                bucket: destinationBucket, 
                for: element, 
                atPrimaryLocation: !bumpToSecondary, 
                iteration: iteration + 1)
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
        let hash1 = primaryHash(of: member)
        let bucket1 = bucket(for: hash1)
        let hash2 = secondaryHash(of: member)
        let bucket2 = bucket(for: hash2)

        if let (_, memberFound) = contents(ofBucket: bucket1) {
            let foundHash1 = primaryHash(of: memberFound)
            let foundHash2 = secondaryHash(of: memberFound)
            if foundHash1 == hash1 && foundHash2 == hash2 {
                return true
            }
        }
        if let (_, memberFound) = contents(ofBucket: bucket2) {
            let foundHash1 = primaryHash(of: memberFound)
            let foundHash2 = secondaryHash(of: memberFound)
            if foundHash1 == hash1 && foundHash2 == hash2 {
                return true
            }
        }

        // If we havent found anything yet, return false
        return false
    }

    /// Removes all elements in the set.
    ///
    /// This method removes all elements by overwriting the set's storage.
    public mutating func removeAll() {
        buckets = [Bucket](repeating: .none, count: capacity)
    }
}

extension CuckooSet: Sequence {
    public func makeIterator() -> IndexingIterator<[Element]> {
        buckets.compactMap { bucket in
            switch bucket {
            case .none:
                return nil
            case .some(_, let element):
                return element
            }
        }
        .makeIterator()
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
