// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AtollRPC",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AtollRPC",
            targets: ["AtollRPC"]
        ),
    ],
    targets: [
        .target(
            name: "AtollRPC",
            dependencies: [],
            path: "Sources/AtollRPC"
        ),
        .testTarget(
            name: "AtollRPCTests",
            dependencies: ["AtollRPC"]
        ),
    ]
)
