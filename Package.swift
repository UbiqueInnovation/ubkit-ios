// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UBKit",
    platforms: [
        .iOS(.v10),
        .watchOS(.v5),
    ],
    products: [
        .library(name: "UBFoundation", type: .dynamic, targets: ["UBFoundation"]),
        .library(name: "UBUserInterface", type: .dynamic, targets: ["UBUserInterface"]),
        .library(name: "UBLocation", type: .dynamic, targets: ["UBLocation"]),
        .library(name: "UBPush", type: .dynamic, targets: ["UBPush"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "UBFoundation"),
        .target(name: "UBUserInterface", dependencies: ["UBFoundation"]),
        .target(name: "UBLocation", dependencies: ["UBFoundation"]),
        .target(name: "UBPush", dependencies: ["UBFoundation"]),
        .testTarget( name: "UBFoundationTests", dependencies: ["UBFoundation"]),
        .testTarget( name: "UBUserInterfaceTests", dependencies: ["UBUserInterface"]),
        .testTarget(name: "UBLocationTests", dependencies: ["UBLocation"]),
    ]
)
