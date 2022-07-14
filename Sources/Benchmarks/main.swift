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

// MARK: CuckooSet

benchmark.add(title: "set/insert", input: [Int].self) { input in
    var testSet = CuckooSet<Int>()
    return { timer in 
        for value in input {
            blackHole(testSet.insert(value).inserted)
        }
    }
}

benchmark.add(title: "set/contains", input: [Int].self) { input in
    let testSet = CuckooSet(input)
    return { timer in 
        for value in input {
            blackHole(testSet.contains(value))
        }
    }
}

benchmark.add(title: "set/remove", input: [Int].self) { input in
    var testSet = CuckooSet(input)
    return { timer in
        for value in input {
            blackHole(testSet.remove(value))
        }
    }
}

benchmark.add(title: "dict/insert", input: [Int].self) { input in
    var testDict = CuckooDictionary<Int, Bool>()
    return { timer in 
        for value in input {
            testDict[value] = .random()
        }
    }
}

benchmark.add(title: "dict/lookup", input: [Int].self) { input in
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
