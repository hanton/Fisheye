// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Fisheye",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Fisheye",
            targets: ["Fisheye"]
        ),
    ],
    targets: [
        .target(
            name: "Fisheye",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FisheyeTests",
            dependencies: ["Fisheye"]
        ),
    ]
)
