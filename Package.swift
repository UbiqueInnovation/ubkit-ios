// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "UBKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .watchOS(.v5),
        .macOS(.v10_15),
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
        .target(name: "UBFoundation", dependencies: ["UBMacros"]),
        .target(name: "UBUserInterface", dependencies: ["UBFoundation"]),
        .target(name: "UBLocation", dependencies: ["UBFoundation"]),
        .target(name: "UBPush", dependencies: ["UBFoundation"]),
        .target(name: "UBQRScanner"),
        .target(name: "UBDevTools", dependencies: ["UBFoundation"]),

        .macro(name: "UBMacros", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
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
