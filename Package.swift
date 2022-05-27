// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "swift-cuckoo-collections",
    products: [
        .library(
            name: "CuckooCollections",
            targets: ["CuckooCollections"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/crichez/swift-fowler-noll-vo",
            .upToNextMinor(from: "0.2.0")),
        .package(
            url: "https://github.com/apple/swift-collections-benchmark", 
            .upToNextMajor(from: "0.0.1")),
    ],
    targets: [
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
)
