//
//  SetAlgebra.swift
//  CuckooSet
//
//  Created by Christopher Richez on January 18 2022
//

extension CuckooSet {
    public mutating func formUnion(with otherSet: Self) {
        insert(contentsOf: otherSet)
    }

    public func union(with otherSet: Self) -> Self {
        var copy = self
        copy.formUnion(with: otherSet)
        return copy
    }

    public mutating func formIntersection(with otherSet: Self) {
        for element in self where !otherSet.contains(element) {
            remove(element)
        }
    }

    public func intersection(with otherSet: Self) -> Self {
        var copy = self
        copy.formIntersection(with: otherSet)
        return copy
    }

    public mutating func formSymmetricDifference(with otherSet: Self) {
        for element in otherSet where !self.insert(element) {
            remove(element)
        }
    }

    public func symmetricDifference(with otherSet: Self) -> Self {
        var copy = self
        copy.formSymmetricDifference(with: otherSet)
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
}