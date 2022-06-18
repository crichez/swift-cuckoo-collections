//
//  CuckooHashTable.swift
//
//
//  Created by Christopher Richez on June 17 2022
//

/// Storage for a cuckoo hash table.
class CuckooStorage<Element> {
    /// The base pointer to the element storage.
    let basePointer: UnsafeMutablePointer<Element?>
    
    /// The number of buckets in the hash table.
    var capacity: Int
    
    /// The number of occupied buckets in the hash table.
    var count: Int
    
    /// Initializes storage by allocating a buffer of the specified capacity.
    init(capacity: Int) {
        self.basePointer = .allocate(capacity: capacity)
        self.basePointer.initialize(repeating: nil, count: capacity)
        self.capacity = capacity
        self.count = 0
    }

    /// Initializes storage by copying the provided storage.
    init(copying other: CuckooStorage) {
        self.basePointer = .allocate(capacity: other.capacity)
        self.basePointer.initialize(from: other.basePointer, count: other.capacity)
        self.capacity = other.capacity
        self.count = other.count
    }
    
    deinit {
        basePointer.deinitialize(count: capacity)
        basePointer.deallocate()
    }
}

extension CuckooStorage {
    subscript(_ offset: Int) -> Element? {
        get {
            basePointer.advanced(by: offset).pointee
        }
        set {
            basePointer.advanced(by: offset).pointee = newValue
        }
    }
}
