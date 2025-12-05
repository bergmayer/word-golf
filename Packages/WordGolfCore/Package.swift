// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WordGolfCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WordGolfCore",
            targets: ["WordGolfCore"]),
    ],
    targets: [
        .target(
            name: "WordGolfCore",
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "WordGolfCoreTests",
            dependencies: ["WordGolfCore"]),
    ]
)
