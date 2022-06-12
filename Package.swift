// swift-tools-version:5.5

import PackageDescription

#if os(Windows)

// We cannot build swift-collections-benchmark on Windows, so exclude it from dependencies
let dependencies: [Package.Dependency] = [
    .package(
        url: "https://github.com/crichez/swift-fowler-noll-vo",
        .upToNextMinor(from: "0.2.0")),
]

// We do not declare the Benchmarks target on Windows
let targets: [Target] = [
    .target(
        name: "CuckooCollections",
        dependencies: [.product(name: "FowlerNollVo", package: "swift-fowler-noll-vo")]),
    .testTarget(
        name: "CuckooCollectionsTests",
        dependencies: ["CuckooCollections"]),
]

#else

// On all other platforms, we assume this builds fine.
let dependencies: [Package.Dependency] = [
    .package(
        url: "https://github.com/crichez/swift-fowler-noll-vo",
        .upToNextMinor(from: "0.2.0")),
    .package(
        url: "https://github.com/apple/swift-collections-benchmark", 
        .upToNextMajor(from: "0.0.1")),
]

let targets: [Target] = [
    .target(
        name: "CuckooCollections",
        dependencies: [.product(name: "FowlerNollVo", package: "swift-fowler-noll-vo")]),
    .testTarget(
        name: "CuckooCollectionsTests",
        dependencies: ["CuckooCollections"]),
    .executableTarget(name: "Benchmarks", dependencies: [
        "CuckooCollections", 
        .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark")]),
]

#endif

// Targets and dependencies are declared above.
let package = Package(
    name: "swift-cuckoo-collections",
    products: [
        .library(name: "CuckooCollections", targets: ["CuckooCollections"]),
    ],
    dependencies: dependencies,
    targets: targets
)
