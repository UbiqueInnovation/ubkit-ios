// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UBKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
        .watchOS(.v5),
        .visionOS(.v1),
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
    ],
    targets: [
        .target(name: "UBFoundation"),
        .target(name: "UBUserInterface", dependencies: ["UBFoundation"]),
        .target(name: "UBLocation", dependencies: ["UBFoundation"]),
        .target(name: "UBPush", dependencies: ["UBFoundation"]),
        .target(name: "UBQRScanner"),
        .target(name: "UBDevTools", dependencies: ["UBFoundation"]),
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
