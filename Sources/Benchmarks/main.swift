//
//  main.swift
//
//  Copyright 2022 Christopher Richez
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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

benchmark.add(title: "CuckooDictionary<Int, Bool> Insert", input: [Int].self) { input in 
    var testDict = CuckooDictionary<Int, Bool>()
    return { timer in 
        for value in input {
            testDict[value] = .random()
        }
    }
}

benchmark.add(title: "CuckooDictionary<Int, Bool> Lookup", input: [Int].self) { input in 
    var testDict = CuckooDictionary<Int, Bool>(capacity: input.count * 2)
    for value in input {
        testDict[value] = .random()
    }
    return { timer in 
        for value in input {
            blackHole(testDict[value])
        }
    }
}

benchmark.main()
