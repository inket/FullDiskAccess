// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullDiskAccess",
    platforms: [.macOS(.v10_14)],
    products: [
        .library(name: "FullDiskAccess", targets: ["FullDiskAccess"]),
    ],
    targets: [
        .target(name: "FullDiskAccess"),
    ]
)
