//
//  main.swift
//
//
//  Created by Christopher Richez on May 27th 2022
//

import CollectionsBenchmark
import CuckooCollections

var benchmark = Benchmark(title: "CuckooCollections Benchmark")

benchmark.add(title: "CuckooSet<Int> Insert", input: [Int].self) { input in
    var testSet = CuckooSet<Int>()
    return { timer in 
        for value in input {
            testSet.insert(value)
        }
    }
}

benchmark.add(title: "CuckooSet<Int> Contains", input: [Int].self) { input in 
    let testSet = CuckooSet(input)
    return { timer in 
        for value in input {
            precondition(testSet.contains(value))
        }
    }
}

benchmark.main()
