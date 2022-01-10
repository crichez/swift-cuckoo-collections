//
//  ComparisonOperations.swift
//  CuckooSet
//
//  Created by Christopher Richez on January 10 2022
//

import FowlerNollVo

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

extension CuckooSet/*: SetAlgebra*/ {
    /// Returns true if the set provided for comparison contains all of this set's elements.
    public func isSubset(of other: Self) -> Bool {
        for element in self where !other.contains(element) {
            return false
        }
        return true
    }

    /// Returns true of the set provided for comparison contains all of this set's elements,
    /// but false if the sets are identical.
    public func isStrictSubset(of other: Self) -> Bool {
        guard self != other else { return false }
        return isSubset(of: other)
    }

    /// Returns true if this set contains all elements of the set provided for comparison.
    public func isSuperset(of other: Self) -> Bool {
        for element in other where !self.contains(element) {
            return false
        }
        return true
    }

    /// Returns true if this set contains all elements of the set provided for comparison,
    /// but false if the sets are identical.
    public func isStrictSuperset(of other: Self) -> Bool {
        guard self != other else { return false }
        return isSuperset(of: other)
    }

    /// Returns true if the set provided for comparison has no elements in common with this set.
    public func isDisjoint(with other: Self) -> Bool {
        for element in self where other.contains(element) {
            return false
        }
        for element in other where self.contains(element) {
            return false
        }
        return true
    }
}