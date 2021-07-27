// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DependencyLookup",
    products: [
        .library(
            name: "DependencyLookup",
            targets: ["DependencyLookup"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "DependencyLookup",
            dependencies: []),
        .testTarget(
            name: "DependencyLookupTests",
            dependencies: ["DependencyLookup"]),
    ]
)
