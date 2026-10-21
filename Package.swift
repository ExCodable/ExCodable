// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "ExCodable",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12),
        .watchOS(.v9)
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
    swiftLanguageModes: [.v5]
)
