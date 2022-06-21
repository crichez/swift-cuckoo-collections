//
//  CuckooSet.swift
//  CuckooSet
//
//  Created by Christopher Richez on January 5th, 2021
//

import FowlerNollVo

// MARK: Storage & Initialization

/// A set variant that uses a cuckoo hashing algorithm.
///
/// `CuckooSet` conforms to `SetAlgebra` and exposes the same API as the Swift standard
/// library `Set`, but requires that `Element` conform to `FNVHashable` since this set needs
/// to use two different hash functions.
public struct CuckooSet<Element: FNVHashable> {
    /// An `Array` of `Optional<Element>` values to use as storage for the set.
    ///
    /// Each optional element is a bucket, where `nil` means the bucket is empty.
    var buckets: CuckooStorage<Element>

    /// The theoretical maximum number of members this set can contain.
    ///
    /// - Note: `CuckooSet` doubles its capacity when `count` reaches roughly half of `capacity`.
    internal(set) public var capacity: Int { 
        get { buckets.capacity }
        set { buckets.capacity = newValue }
    }

    /// The number of members contained in this set.
    internal(set) public var count: Int { 
        get { buckets.count }
        set { buckets.count = newValue }
    }

    /// Initializes an empty `CuckooSet` with the provided capacity.
    ///
    /// - Parameter capacity: the number of buckets in the set hash table, defaults to 32
    ///
    /// - Note: `CuckooSet` doubles its capacity when `count` reaches roughly half of `capacity`.
    /// When allocating a set to store a known number of members,
    /// request a capacity of at least double the known number of members.
    public init(capacity: Int = 32) {
        self.buckets = .init(capacity: capacity)
    }

    // MARK: Cuckoo Internals

    /// Computes the primary hash of the provided element.
    ///
    /// The primary hash uses the FNV-1a hash function with a 64-bit digest.
    ///
    /// - Parameter member: the set member to hash
    ///
    /// - Returns: The primary hash function digest as an `UInt64`.
    func primaryHash(of member: Element) -> UInt64 {
        var hasher = FNV64a()
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
        var hasher = FNV64()
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
    ///
    /// - Complexity: `O(n)` where `n` is `count`.
    mutating func expand() {
        var expandedSet = CuckooSet<Element>(capacity: capacity * 2)
        for member in self {
            expandedSet.insert(member)
        }
        self = expandedSet
    }

    /// Checks whether the storage is uniquely referenced, and replaces it with a copy if not.
    mutating func copyOnWrite() {
        if !isKnownUniquelyReferenced(&buckets) {
            self.buckets = CuckooStorage(copying: buckets)
        }
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
        copyOnWrite()
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
        let newBucket = bucket1 == bucket ? bucket2 : bucket1
        // Check whether the new bucket is occupied
        if buckets[newBucket] == nil {
            buckets[newBucket] = bumpedMember
            return nil
        } else {
            return (bumpedMember, newBucket)
        }
    }

    // MARK: Convenience

    /// Inserts each element of the provided `Sequence` into the set.
    ///
    /// - Complexity: `O(n)` where `n` is `otherSequence.count`.
    public mutating func insert<S>(contentsOf otherSequence: S)
    where S : Sequence, S.Element == Element {
        copyOnWrite()
        for element in otherSequence {
            insert(element)
        }
    }
    
    /// Inserts each element of the provided `Collection` into the set.
    ///
    /// - Complexity: `O(n)` where `n` is `otherCollection.count`.
    public init<C: Collection>(_ otherCollection: C) where C.Element == Element {
        var cuckooSet = CuckooSet<Element>(capacity: otherCollection.count * 2)
        cuckooSet.insert(contentsOf: otherCollection)
        self = cuckooSet
    }

    /// Removes all members in the set and resets the storage to the default size.
    public mutating func removeAll() {
        buckets = CuckooStorage(capacity: 32)
    }
}

extension CuckooSet: Sequence {
    public struct Iterator: IteratorProtocol {
        let set: CuckooSet
        var cursor: Int

        public mutating func next() -> Element? {
            guard cursor < set.capacity else { 
                return nil 
            }
            guard let member = set.buckets[cursor] else {
                cursor += 1
                return next()
            }
            cursor += 1
            return member
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(set: self, cursor: 0)
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
}

extension CuckooSet where Element : Hashable {
    /// Initializes a `CuckooSet` by inserting each element in the provided `Set`.
    ///
    /// - Complexity: `O(n)` where `n` is `otherSet.count`.
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
        var lhsHasher = FNV64a()
        var rhsHasher = FNV64a()
        lhs.hash(into: &lhsHasher)
        rhs.hash(into: &rhsHasher)
        return lhsHasher.digest == rhsHasher.digest
    }
}
