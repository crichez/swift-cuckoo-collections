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

    /// Doubles the number of buckets in the set, and re-hashes everything.
    /// Returns true if the new element insertion suceeded.
    mutating func expand(
        toInsert newElement: Element
    ) -> (inserted: Bool, memberAfterInsert: Element) {
        var expandedSet = CuckooSet<Element>(capacity: capacity * 2)
        for bucket in buckets {
            switch bucket {
            case .some(_, let element):
                expandedSet.insert(element)
            case .none:
                continue
            }
        }
        self = expandedSet
        return insert(newElement)
    }

    /// Moves the element at the source bucket to its alternative location and returns true
    /// once the new element insertion succeeded.
    mutating func bump(
        from source: Int, 
        toInsert newElement: Element, 
        atPrimaryLocation: Bool, 
        iteration: Int = 0
    ) -> (succeeded: Bool, expanded: Bool) {
        // At iteration 20 we are probably in a loop, 
        // so expand the set's storage to reduce the collision rate
        guard iteration < 20 else { 
            return (succeeded: expand(toInsert: newElement).inserted, expanded: true) 
        }

        // Fetch the current contents of the bucket
        guard let (hash, element) = contents(ofBucket: source) else {
            fatalError("requested a bump from an empty bucket")
        }

        // Overwrite it with the new element
        let newHash = atPrimaryLocation ? primaryHash(of: newElement) : secondaryHash(of: newElement)
        buckets[source] = .some(newHash, newElement)

        // Find out if the bumped element is at its primary or secondary bucket
        let primaryHash = primaryHash(of: element)
        let secondaryHash = secondaryHash(of: element)
        let bumpToSecondary = hash == primaryHash
        let newBumpedHash = bumpToSecondary ? secondaryHash : primaryHash

        // Move the element to its alternative bucket
        let destinationBucket = bucket(for: newBumpedHash)
        if contents(ofBucket: destinationBucket) == nil {
            // If the secondary location is empty, insert it directly
            buckets[destinationBucket] = .some(newBumpedHash, element)
            return (true, false)
        } else {
            // If the secondary location if full, request a bump
            return bump(
                from: destinationBucket, 
                toInsert: element, 
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