# CuckooCollections

A Swift package for open-addressed sets and dictionaries that use the 
[cuckoo hasing algorithm](https://en.wikipedia.org/wiki/Cuckoo_hashing).

## Overview

Import the `CuckooCollections` module to use two new data structures that feature constant-time lookups, insertions and removals:
* `CuckooSet` *(prototype)*
* `CuckooDictionary` *(not implemented)*

This cuckoo hashing algorithm uses `FNV-1` and `FNV-1a` with a 64-bit digest.
The hash function implementation is also open-source, the code is available 
[here](https://github.com/crichez/swift-fowler-noll-vo).

## Platforms

This package is tested in continuous integration on the following platforms:
* Ubuntu 20.04
* Windows Server 2019
* macOS 11.5
* iOS 15.0
* tvOS 15.0
* watchOS 8.0

## Versioning

As a Swift Package Manager project, this package uses semantic versioning rules.
**All releases before `1.0.0` are considered pre-release.** Under pre-release rules,
code-breaking changes may be introduced with a minor version bump. To avoid this, specify
the version requirement in your package manifest as follows:

```swift
.package(url: "https://github.com/crichez/swift-cuckoo-collections", .upToNextMinor(from: "0.0.1"))
```