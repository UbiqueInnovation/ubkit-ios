// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "UBKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        .watchOS(.v7),
        .macOS(.v10_15),
        .visionOS(.v2),
        .macOS(.v14)
    ],
    products: [
        .library(name: "UBFoundation", targets: ["UBFoundation"]),
        .library(name: "UBUserInterface", targets: ["UBUserInterface"]),
        .library(name: "UBLocation", targets: ["UBLocation"]),
        .library(name: "UBPush", targets: ["UBPush"]),
        .library(name: "UBQRScanner", targets: ["UBQRScanner"]),
        .library(name: "UBDevTools", targets: ["UBDevTools"]),
    ],
    dependencies: [
        .package(url: "https://github.com/UbiqueInnovation/ios-local-networking.git", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-syntax", .upToNextMajor(from: "509.0.0")),
    ],
    targets: [
        .target(
            name: "UBFoundation",
            dependencies: ["UBMacros"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "UBUserInterface",
            dependencies: ["UBFoundation"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "UBLocation",
            dependencies: ["UBFoundation"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "UBPush",
            dependencies: ["UBFoundation"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "UBQRScanner",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "UBDevTools",
            dependencies: ["UBFoundation"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .macro(name: "UBMacros", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
        ]),
        .testTarget(name: "UBFoundationTests",
                    dependencies: ["UBFoundation", .product(name: "UBLocalNetworking", package: "ios-local-networking")],
                    resources: [
                        .copy("TestResources"),
                    ]),
        .testTarget(name: "UBUserInterfaceTests",
                    dependencies: ["UBUserInterface"]),
        .testTarget(name: "UBLocationTests",
                    dependencies: ["UBLocation"]),
    ]
)
