// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UBKit",
    platforms: [
        .iOS(.v10),
        .watchOS(.v5),
    ],
    products: [
        .library(name: "UBFoundation", targets: ["UBFoundation"]),
        .library(name: "UBUserInterface", targets: ["UBUserInterface"]),
        .library(name: "UBLocation", targets: ["UBLocation"]),
        .library(name: "UBPush", targets: ["UBPush"]),
        .library(name: "UBQRScanner", targets: ["UBQRScanner"]),
        .library(name: "UBDevTools", targets: ["UBDevTools"])
    ],
    dependencies: [],
    targets: [
        .target(name: "UBFoundation"),
        .target(name: "UBUserInterface", dependencies: ["UBFoundation"]),
        .target(name: "UBLocation", dependencies: ["UBFoundation"]),
        .target(name: "UBPush", dependencies: ["UBFoundation"]),
        .target(name: "UBQRScanner"),
        .target(name: "UBDevTools", dependencies: ["UBFoundation"]),
        .testTarget(name: "UBFoundationTests",
                    dependencies: ["UBFoundation"],
                    resources: [
                        .copy("TestResources"),
                    ]),
        .testTarget(name: "UBUserInterfaceTests",
                    dependencies: ["UBUserInterface"]),
        .testTarget(name: "UBLocationTests",
                    dependencies: ["UBLocation"]),
    ]
)
