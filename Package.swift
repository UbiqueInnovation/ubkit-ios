// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UBKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        .watchOS(.v5),
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
        .target(
            name: "UBFoundation",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "UBUserInterface",
            dependencies: ["UBFoundation"],
            swiftSettings: [
                .swiftLanguageVersion(.v6)
            ]
        ),
        .target(
            name: "UBLocation",
            dependencies: ["UBFoundation"],
            swiftSettings: [
                .swiftLanguageVersion(.v6)
            ]
        ),
        .target(
            name: "UBPush",
            dependencies: ["UBFoundation"],
            swiftSettings: [
                .swiftLanguageVersion(.v6)
            ]
        ),
        .target(
            name: "UBQRScanner",
            swiftSettings: [
                .swiftLanguageVersion(.v6)
            ]
        ),
        .target(
            name: "UBDevTools",
            dependencies: ["UBFoundation"],
            swiftSettings: [
                .swiftLanguageVersion(.v6)
            ]
        ),
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
