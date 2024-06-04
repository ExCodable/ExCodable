// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "ExCodable",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .macOS(.v11),
        .watchOS(.v4)
    ],
    products: [
        .library(name: "ExCodable", targets: ["ExCodable"]),
        // .library(name: "ExCodable-Static", type: .static, targets: ["ExCodable"]),
        .library(name: "ExCodable-Dynamic", type: .dynamic, targets: ["ExCodable"])
    ],
    dependencies: [
        // .package(url: "https://github.com/user/repo", from: "1.0.0")
    ],
    targets: [
        .target(name: "ExCodable", dependencies: []),
        .testTarget(name: "ExCodableTests", dependencies: ["ExCodable"])
    ],
    swiftLanguageVersions: [.v5]
)
