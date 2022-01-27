//
//  CuckooDictionary.swift
//  CuckooDictionary
//
//  Created by Christopher Richez on January 24th, 2021
//

import FowlerNollVo

// MARK: Storage & Initialization

/// A dictionary where `Key` conforms to `FNVHashable`.
public struct CuckooDictionary<Key, Value>: ExpressibleByDictionaryLiteral 
where Key : FNVHashable {
    /// An array where each element is a tuple containing a hashed key and value, 
    /// or nil of the bucket is empty.
    var buckets: [(key: Key, value: Value)?]

    /// The number of key-value pairs in the dictionary.
    public var count: Int

    /// Initializes an empty dictionary with the specified capacity,
    /// or with the default capacity of 32 key-value pairs if none was specified.
    public init(capacity: Int = 32) {
        self.buckets = .init(repeating: nil, count: capacity)
        self.count = 0
    }

    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(capacity: elements.count * 2 > 32 ? elements.count * 2 : 32)
        for (key, value) in elements {
            insert(key: key, value: value)
        }
    }
}

// MARK: Cuckoo Hashing

extension CuckooDictionary {
    /// Returns the hash of the provided key using the primary hash function.
    func primaryHash(of key: Key) -> UInt64 {
        var hasher = FNV1aHasher<UInt64>()
        hasher.combine(key)
        return hasher.digest
    }

    /// Returns the hash of the provided key using the secondary hash function.
    func secondaryHash(of key: Key) -> UInt64 {
        var hasher = FNV1Hasher<UInt64>()
        hasher.combine(key)
        return hasher.digest
    }

    /// Returns the index of the bucket where the provided hashed key should be stored.
    func bucket(for hashedKey: UInt64) -> Int {
        Int(hashedKey % UInt64(capacity))
    }

    /// Doubles the capacity of the set and re-inserts all key-value pairs.
    mutating func expand() {
        var expandedDict = Self(capacity: capacity * 2)
        for (key, value) in self {
            expandedDict.insert(key: key, value: value)
        }
        self = expandedDict
    }

    /// Displaces the element at the specified bucket and either moves or returns it.
    ///
    /// - Parameters: 
    ///     - bucket: the bucket to insert the provided elements at
    ///     - key: the key to insert
    ///     - value: the value to insert
    ///
    /// - Returns: 
    /// If all elements are assigned a bucket, returns `nil`.
    /// If the alternative location for the bumped element is occupied,
    /// returns a truple with the `bumpedKey`, `bumpedValue`, and `nextBucket` - 
    /// the occupied bucket where the bumped element would have been inserted.
    mutating func bump(
        bucket: Int, 
        forKey key: Key, 
        andValue value: Value
    ) -> (key: Key, value: Value, bucket: Int)? {
        // Get the current contents of the bucket
        guard let (bumpedKey, bumpedValue) = buckets[bucket] else {
            fatalError("requested a bump from an empty bucket")
        }
        // Overwrite the bucket with the new key-value pair
        buckets[bucket] = (key, value)
        // Get the new bucket of the bumped key
        let bumpedKeyHash1 = primaryHash(of: bumpedKey)
        let bumpedKeyHash2 = secondaryHash(of: bumpedKey)
        let isAtBucket1 = self.bucket(for: bumpedKeyHash1) == bucket
        let newBucket = self.bucket(for: isAtBucket1 ? bumpedKeyHash2 : bumpedKeyHash1)
        // Check if the new bucket is empty
        if buckets[newBucket] == nil {
            // If so, write to the new bucket
            buckets[newBucket] = (bumpedKey, bumpedValue)
            return nil
        } else {
            return (key: bumpedKey, value: bumpedValue, bucket: newBucket)
        }
    }
}

// MARK: Public API

extension CuckooDictionary {
    /// The number of available buckets in the hash table.
    public var capacity: Int {
        buckets.count
    }

    /// Updates the value associated with a given key, or inserts it if the key doesn't already
    /// exist.
    ///
    /// This method is equivalent to subscript assignment, but will not remove keys when a `nil`
    /// value is provided.
    ///
    /// - Parameters:
    ///     - key: the key for which to update the value
    ///     - value: the new value to associate with the key
    ///
    /// - Returns: Returns `true` if the key didn't already exist.
    @discardableResult
    public mutating func updateValue(forKey key: Key, with newValue: Value) -> Bool {
        // Keep the load factor of the dictionary under 0.5
        if capacity < count * 2 { 
            expand()
        }

        // Get both hashes of the key
        let hash1 = primaryHash(of: key)
        let hash2 = secondaryHash(of: key)

        // Get both bucket indices for the key
        let bucket1 = bucket(for: hash1)
        let bucket2 = bucket(for: hash2)

        // Check both buckets for a matching key
        for bucket in [bucket1, bucket2] {
            // Check whether the bucket is full
            if let (keyFound, _) = buckets[bucket] {
                // If so, get both hashes of the key at that bucket
                let keyFoundHash1 = primaryHash(of: keyFound)
                let keyFoundHash2 = secondaryHash(of: keyFound)
                // Check for a perfect match
                if keyFoundHash1 == hash1 && keyFoundHash2 == hash2 {
                    // If this a perfect match, update the value
                    buckets[bucket] = (key, newValue)
                    return false
                }
            }
        }

        // If we need to insert the key, check the contents of bucket one
        if buckets[bucket1] == nil {
            // If it is open, assign the new element
            buckets[bucket1] = (key, newValue)
            // Increment count
            count += 1
            // Return true to signal we had to insert the key
            return true
        } else {
            // If it is occupied, prepare to bump the element off that bucket
            var bumped = (key: key, value: newValue, bucket: bucket1)
            // Keep track of the number of consecutive bumps to detect loops
            var bumpCount = 0
            // Keep bumping until the bump operation returns nil
            while let nextBump = bump(
                bucket: bumped.bucket, 
                forKey: bumped.key, 
                andValue: bumped.value
            ) {
                // If we are in a loop, expand and re-insert the bumped element
                guard bumpCount < 20 else {
                    expand()
                    return insert(key: nextBump.key, value: nextBump.value)
                }
                // Increment the bump count
                bumpCount += 1
                // Get ready to bump the next bucket
                bumped = nextBump
            }
            count += 1
            return true
        }
    }

    /// Removes the provided key and its associated value from the dictionary.
    ///
    /// This method is equivalent to subscript removal, 
    /// but returns `true` if the key was removed.
    ///
    /// - Parameter key: the key to remove
    ///
    /// - Returns: Returns `true` if the key was removed, `false` if it didn't exist.
    @discardableResult
    public mutating func remove(key: Key) -> Bool {
        // Get both hashes of the key
        let hash1 = primaryHash(of: key)
        let hash2 = secondaryHash(of: key)

        // Get both bucket indices for the key
        let bucket1 = bucket(for: hash1)
        let bucket2 = bucket(for: hash2)

        // Check both buckets for a matching key
        for bucket in [bucket1, bucket2] {
            // Check whether the bucket is full
            if let (keyFound, _) = buckets[bucket] {
                // If so, get both hashes of the key at that bucket
                let keyFoundHash1 = primaryHash(of: keyFound)
                let keyFoundHash2 = secondaryHash(of: keyFound)
                // Check for a perfect match
                if keyFoundHash1 == hash1 && keyFoundHash2 == hash2 {
                    // If this a perfect match, update the value
                    buckets[bucket] = nil
                    count -= 1
                    return true
                }
            }
        }

        // If we haven't found a perfect match yet, return false
        return false
    }

    /// Strictly inserts the provided key-value pair into the dictionary.
    ///
    /// If the key already exists, no work is done.
    ///
    /// - Parameters:
    ///     - key: the key to insert
    ///     - value: the value to associate with the new key
    ///
    /// - Returns: Returns `true` if the key was inserted, `false` if it already exists.
    @discardableResult
    public mutating func insert(key: Key, value: Value) -> Bool {
        // Keep the load factor of the dictionary under 0.5
        if capacity < count * 2 { 
            expand()
        }

        // Get both hashes of the key
        let hash1 = primaryHash(of: key)
        let hash2 = secondaryHash(of: key)

        // Get both bucket indices for the key
        let bucket1 = bucket(for: hash1)
        let bucket2 = bucket(for: hash2)

        // Check both buckets for a matching key
        for bucket in [bucket1, bucket2] {
            // Check whether the bucket is full
            if let (keyFound, _) = buckets[bucket] {
                // If so, get both hashes of the key at that bucket
                let keyFoundHash1 = primaryHash(of: keyFound)
                let keyFoundHash2 = secondaryHash(of: keyFound)
                // Check for a perfect match
                if keyFoundHash1 == hash1 && keyFoundHash2 == hash2 {
                    // If this a perfect match, do nothing and return false
                    return false
                }
            }
        }

        // If we need to insert the key, check the contents of bucket one
        if buckets[bucket1] == nil {
            // If it is open, assign the new element
            buckets[bucket1] = (key, value)
            // Increment count
            count += 1
            // Return true to signal we had to insert the key
            return true
        } else {
            // If it is occupied, prepare to bump the element off that bucket
            var bumped = (key: key, value: value, bucket: bucket1)
            // Keep track of the number of consecutive bumps to detect loops
            var bumpCount = 0
            // Keep bumping until the bump operation returns nil
            while let nextBump = bump(
                bucket: bumped.bucket, 
                forKey: bumped.key, 
                andValue: bumped.value
            ) {
                // If we are in a loop, expand and re-insert the bumped element
                guard bumpCount < 20 else {
                    expand()
                    return insert(key: nextBump.key, value: nextBump.value)
                }
                // Increment the bump count
                bumpCount += 1
                // Get ready to bump the next bucket
                bumped = nextBump
            }
            count += 1
            return true
        }
    }

    public subscript(key: Key) -> Value? {
        get {
            // Compute the hashes for this key
            let hash1 = primaryHash(of: key)
            let hash2 = secondaryHash(of: key)
            // Check for a match at both potential buckets
            for keyValuePair in [buckets[bucket(for: hash1)], buckets[bucket(for: hash2)]] {
                // Check whether a key-value pair exists at that bucket
                if let (candidate, value) = keyValuePair {
                    // If so, get the hashes for the key found at this bucket
                    let candidateHash1 = primaryHash(of: candidate)
                    let candidateHash2 = secondaryHash(of: candidate)
                    // Check for a match of both hashes
                    if candidateHash1 == hash1 && candidateHash2 == hash2 {
                        // If both hashes match, this is likely the requested key
                        return value
                    }
                }
            }
            // If no perfect match was found so far, this key doesn't exist
            return nil
        }

        set {
            // Check whether this is an insertion/update or removal
            if let newValue = newValue {
                updateValue(forKey: key, with: newValue)
            } else {
                remove(key: key)
            }
        }
    }
}

// MARK: Sequence

extension CuckooDictionary: Sequence {
    public func makeIterator() -> IndexingIterator<[(key: Key, value: Value)]> {
        buckets.compactMap { $0 }.makeIterator()
    }
}