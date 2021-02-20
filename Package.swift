// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ExCodable",
    products: [
        .library(
            name: "ExCodable",
            targets: ["ExCodable"]),
    ],
    dependencies: [
        // .package(url: "https://github.com/user/repo", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ExCodable",
            dependencies: []),
        .testTarget(
            name: "ExCodableTests",
            dependencies: ["ExCodable"]),
    ],
    swiftLanguageVersions: [.v5]
)
