//
//  CuckooSet.swift
//  CuckooSet
//
//  Created by Christopher Richez on January 5th, 2021
//

import FowlerNollVo

/// A set that uses the cuckoo algorithm to insert each member.
public struct CuckooSet<Element: FNVHashable> {
    /// A bucket in a `CuckooSet`.
    enum Bucket {
        case none
        case some(UInt64, Element)
    }

    /// An array of buckets used as storage for the set.
    var buckets: [Bucket]

    /// Initializes a `CuckooSet` with the provided capacity
    public init(capacity: Int = 32) {
        self.buckets = [Bucket](repeating: .none, count: capacity)
        self.count = 0
    }

    public init() {
        self.init(capacity: 32)
    }

    /// The capacity of the set.
    public var capacity: Int {
        buckets.count
    }

    /// The number of initialized elements in the set.
    public var count: Int

    /// Computes the primary hash of the provided element.
    func primaryHash(of element: Element) -> UInt64 {
        var hasher = FNV1aHasher<UInt64>()
        hasher.combine(element)
        return hasher.digest
    }

    /// Computes the secondary hash of the provided element.
    func secondaryHash(of element: Element) -> UInt64 {
        var hasher = FNV1Hasher<UInt64>()
        hasher.combine(element)
        return hasher.digest
    }
    
    /// Computes the bucket the provided hash should be stored in.
    func bucket(for hash: UInt64) -> Int {
        Int(hash % UInt64(capacity))
    }

    /// Retrieves the element at the specified bucket, or `nil` if the bucket is empty.
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

    /// Moves the element at the source bucket to its alternative location and returns true
    /// once the new element insertion succeeded.
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
    public mutating func insert<S>(contentsOf newElements: S) 
    where S : Sequence, S.Element == Element {
        for element in newElements {
            insert(element)
        }
    }

    /// Returns true if the provided element exists in the set.
    public func contains(_ element: Element) -> Bool {
        let hash1 = primaryHash(of: element)
        let bucket1 = bucket(for: hash1)
        let hash2 = secondaryHash(of: element)
        let bucket2 = bucket(for: hash2)

        if let (_, elementFound) = contents(ofBucket: bucket1) {
            let foundHash1 = primaryHash(of: elementFound)
            let foundHash2 = secondaryHash(of: elementFound)
            if foundHash1 == hash1 && foundHash2 == hash2 {
                return true
            }
        }
        if let (_, elementFound) = contents(ofBucket: bucket2) {
            let foundHash1 = primaryHash(of: elementFound)
            let foundHash2 = secondaryHash(of: elementFound)
            if foundHash1 == hash1 && foundHash2 == hash2 {
                return true
            }
        }

        // If we havent found anything yet, return false
        return false
    }

    /// Removes all elements in the set.
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
