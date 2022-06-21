//
//  CuckooDictionary.swift
//  CuckooDictionary
//
//  Created by Christopher Richez on January 24th, 2021
//

import FowlerNollVo

// MARK: Storage & Initialization

/// A `Dictionary` equivalent that uses a cuckoo hashing algorithm.
///
/// `CuckooDictionary` exposes the same subscript-based API as Swift's `Dictionary`,
/// along with common methods for more specific use cases:
/// * `updateValue(forKey:with:)` for updates & insertions only
/// * `insert(key:value:)` for strict insertions
/// * `remove(key:)` for strict removals
///
/// These additional methods also return useful information on the type of work performed,
/// which may not be available through subscript mutation.
public struct CuckooDictionary<Key: FNVHashable, Value>: ExpressibleByDictionaryLiteral {
    /// An array where each element is a tuple containing a hashed key and value, 
    /// or nil of the bucket is empty.
    var buckets: CuckooStorage<(key: Key, value: Value)>

    /// The number of key-value pairs in the dictionary.
    private(set) public var count: Int {
        get { buckets.count }
        set { buckets.count = newValue }
    }

    /// The number of available buckets in the hash table.
    ///
    /// When inserting new values, `capacity` is doubled if `count`
    /// exceeds half of the current capacity. This helps reduce the complexity of insertions
    /// by using more memory as a trade-off. The capacity of the dictionary may also double
    /// with a lower load factor if a number of consecutive insertions fail.
    private(set) public var capacity: Int {
        get { buckets.capacity }
        set { buckets.capacity = newValue }
    }

    /// Initializes an empty dictionary with the specified capacity,
    /// or with the default capacity of 32 key-value pairs if none was specified.
    public init(capacity: Int = 32) {
        self.buckets = CuckooStorage(capacity: capacity)
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
        var hasher = FNV64a()
        hasher.combine(key)
        return hasher.digest
    }

    /// Returns the hash of the provided key using the secondary hash function.
    func secondaryHash(of key: Key) -> UInt64 {
        var hasher = FNV64()
        hasher.combine(key)
        return hasher.digest
    }

    /// Returns the index of the bucket where the provided hashed key should be stored.
    ///
    /// - Warning:
    /// The bucket index returned by this method is dependent upon the capacity of the hash
    /// table at the time the mathod is called. After `expand()` is called, all previously
    /// computed bucket indexes are invalid. Attempting insert into or bump from an invalid
    /// index may result in runtime errors and data loss. 
    func bucket(for hashedKey: UInt64) -> Int {
        Int(hashedKey % UInt64(capacity))
    }

    /// Checks whether the buckets storage is uniquely references, and copies it if not.
    mutating func copyOnWrite() {
        if !isKnownUniquelyReferenced(&buckets) {
            self.buckets = CuckooStorage(copying: buckets)
        }
    }

    /// Doubles the capacity of the set and re-inserts all key-value pairs.
    /// 
    /// This method ensures that the `count` before and after expansion are the same.
    ///
    /// - Warning: 
    /// If expanding during an insertion, note that previously computed bucket indexes are
    /// rendered invalid by the expansion. Attempting to insert into or bump from a bucket index
    /// computed before the expansion may result in runtime errors and data loss.
    mutating func expand() {
        var expandedDict = Self(capacity: capacity * 2)
        for (key, value) in self {
            expandedDict.insert(key: key, value: value)
        }
        self = expandedDict
    }

    /// Displaces the element at the specified bucket and either moves or returns it.
    ///
    /// This method only performs one bump cycle, meaning it won't displace more than one
    /// element at a time. When the alternative bucket for a displaced item is occupied, the
    /// displaced element and bucket index are returned for the caller to attempt another bump.
    /// It is important that the caller keep track of the number of consecutive bumps for a single
    /// insertion and expand the table as necessary.
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
        copyOnWrite()
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
        copyOnWrite()
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
        copyOnWrite()
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
        copyOnWrite()
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

    /// Access or mutate the value associated the the provided key.
    ///
    /// When using this subscript to remove a key-value pair, passing `nil` as a value
    /// also removes the key from the dictionary.
    ///
    /// - Parameter key: the key for which to update or remove a value
    ///
    /// - Returns: 
    /// If the key exists in the dictionary, returns its associated value.
    /// If the key does not exist, returns `nil`.
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
    public struct Iterator: IteratorProtocol {
        private let dict: CuckooDictionary
        private var cursor: Int = 0
        private var found: Int = 0

        init(_ dict: CuckooDictionary) {
            self.dict = dict
        }

        public mutating func next() -> (key: Key, value: Value)? {
            guard cursor < dict.capacity else { return nil }
            guard let element = dict.buckets[cursor] else {
                cursor += 1
                return next()
            }
            cursor += 1
            return element
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(self)
    }
}

// MARK: Keys

extension CuckooDictionary {
    /// A sequence that includes only the keys of a `CuckooDictionary`.
    public struct Keys: Sequence {
        let dict: CuckooDictionary

        /// The iterator for the keys of a `CuckooDictionary`.
        public struct Iterator: IteratorProtocol {
            let dict: CuckooDictionary
            var dictIterator: CuckooDictionary.Iterator

            init(_ dict: CuckooDictionary) {
                self.dict = dict
                self.dictIterator = dict.makeIterator()
            }

            /// Returns the next element in the keys sequence, or `nil` after the last key.
            public mutating func next() -> Key? {
                dictIterator.next()?.key
            }
        }
        
        /// Returns an iterator for the keys sequence of this dictionary.
        public func makeIterator() -> Iterator {
            Iterator(dict)
        }
    }

    /// A sequence that includes only the keys of a `CuckooDictionary`.
    /// 
    /// - Complexity: O(1).
    public var keys: Keys {
        Keys(dict: self)
    }
}

// MARK: Values

extension CuckooDictionary {
    /// A sequence that includes only the values of a `CuckooDictionary`.
    public struct Values: Sequence {
        let dict: CuckooDictionary

        /// The iterator for the values of a `CuckooDictionary`.
        public struct Iterator: IteratorProtocol {
            let dict: CuckooDictionary
            var dictIterator: CuckooDictionary.Iterator

            init(_ dict: CuckooDictionary) {
                self.dict = dict
                self.dictIterator = dict.makeIterator()
            }

            /// Returns the next element in the values sequence, or `nil` after the last value.
            public mutating func next() -> Value? {
                dictIterator.next()?.value
            }
        }
        
        /// Returns an iterator for the values sequence of this dictionary.
        public func makeIterator() -> Iterator {
            Iterator(dict)
        }
    }

    /// A sequence that includes only the values of a `CuckooDictionary`.
    /// 
    /// - Complexity: O(1).
    public var values: Values {
        Values(dict: self)
    }
}
