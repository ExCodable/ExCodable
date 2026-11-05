// swift-tools-version: 6.4

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ExCodable",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v13), // replace .v12 for Regex
        .watchOS(.v9)
    ],
    products: [
        .library(name: "ExCodable", targets: ["ExCodable"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "604.0.0"),
    ],
    targets: [
        .target(name: "ExCodable", dependencies: ["ExCodableMacros"]),
        .macro(
            name: "ExCodableMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "ExCodableTests",
            dependencies: [
                "ExCodable",
                "ExCodableMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
