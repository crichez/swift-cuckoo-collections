# Benchmarking Guide

This package supports benchmarking on Linux and macOS using the 
[swift-collections-benchmark](https://github.com/apple/swift-collections-benchmark) API.

## When to Run Benchmarks

Benchmarks are required for every pull request that includes changes to code in the 
`CuckooCollections` target. This does not include documentation or changes to benchmark
configuration.

Whenever a change is suggested to the implementation of an existing method,
running before and after benchmark comparisons help avoid unexpected performance
regressions. If the change is expected to improve performance, the benchmarks should justify
that change. When new methods or features are added, bechmark results help measure the 
complexity of the new method or feature. 

## How to Run Benchmarks

The recommended approach depends on the changes requested.

### Implementation Changes

Implementation changes should run two benchmarks to compare the before and after performance
of a given operation. The following example runs two benchmarks: one on the `main` branch
(the before benchmark) and one on the `set-insert-optimization-1` branch (the after
benchmark).

Navigate, checkout `main` and run 5 cycles of the "CuckooSet<Int> Insert" task:
```
$ cd swift-cuckoo-collections
$ git checkout main
$ swift run -c release Benchmarks run oldResults.json --cycles 5 --filter "CuckooSet<Int> Insert"
...
Finished in 235s
```

Checkout `set-insert-optimization-1` and run 5 cycles of the "CuckooSet<Int> Insert" task:
```
$ git checkout set-insert-optimizaton-1
$ swift run -c release Benchmarks run newResults.json --cycles 5 --filter "CuckooSet<Int> Insert"
...
Finished in 180s
```

Compare `oldResults.json` to `newResults.json`, and output a graph to `diff.html`:
```
$ swift run -c release Benchmarks results compare oldResults.json newResults.json --output diff.html
...
Tasks with difference scores larger than 1.05:
  Score   Sum     Improvements Regressions  Name
  1.341   1.341   1.341(#76)   1.000(#0)    CuckooSet<Int> Insert (*)
1 images written to diff.html
```

When justifying performance improvements in a pull request, including the comparison
scores is usually enough. Graphs may be included, but should be removed from source
control before the PR is merged.

### New Features

New features need to configure a new benchmark task.
All benchmark tasks are declared in `Sources/Benchmarks/main.swift`. 
For more details or to learn more about the benchmarking API, see 
[the project's getting started guide](https://github.com/apple/swift-collections-benchmark/blob/main/Documentation/01%20Getting%20Started.md).
The following example configures a benchmark for the `insert(_)` method.

```swift
benchmark.add(title: "CuckooSet<Int> Insert", input: [Int].self) { input in
    var testSet = CuckooSet<Int>()
    return { timer in 
        for value in input {
            testSet.insert(value)
        }
    }
}
```

While peformance comparisons are printed to the terminal, single task runs are not.
The following shell session also outputs a graph to `results.png`.
```
$ swift run -c Benchmarks run results.json --cycles 5 --filter "CuckooSet<Int> Insert"
...
Finished in 180s
$ swift run -c Benchmarks render results.json results.png
```

When sharing benchmark results in a pull request for a new feature, you don't need to
include any supporting evidence. Include the complexity of the method, property or
subscript in the inline documentation for changes. These will be verified locally by
the project maintainer(s).
