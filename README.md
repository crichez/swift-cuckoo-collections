# CuckooCollections

A Swift package for open-addressed sets and dictionaries that use the 
[cuckoo hasing algorithm](https://en.wikipedia.org/wiki/Cuckoo_hashing).

## Overview

Import the `CuckooCollections` module to use two new data structures that feature 
constant-time lookups, insertions and removals:
* `CuckooSet`
* `CuckooDictionary`

This cuckoo hashing algorithm uses `FNV-1` and `FNV-1a` with a 64-bit digest.
The hash function implementation is also open-source, the code is available 
[here](https://github.com/crichez/swift-fowler-noll-vo).

## Platforms

This package was last tested on the following platforms:
* Ubuntu 20.04
* Windows Server 2019
* macOS 11.5
* iOS 15.2
* tvOS 15.2
* watchOS 8.3

## Versioning

This project is no longer maintained, and is a read-only archive. The code within 
is still a working cuckoo hash table implementation that may be useful for reference. 
The poor time and memory performance of the hash table is the primary cause for discontinued 
development.
