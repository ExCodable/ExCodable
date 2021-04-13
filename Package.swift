// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ExCodable",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
        .macOS(.v10_10),
        .watchOS(.v2)
    ],
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
