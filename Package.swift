// swift-tools-version:5.0
//
//  UBFoundation

import PackageDescription

let package = Package(
    name: "UBFoundation",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "UBFoundation", targets: ["UBFoundation"]),
        .library(name: "UBFoundationPush", targets: ["UBFoundationPush"]),
        .library(name: "UBFoundationLocation", targets: ["UBFoundationLocation"])
    ],
    targets: [
        .target(name: "UBFoundation", path: "Sources"),
        .target(name: "UBFoundationPush", dependencies: ["UBFoundation"], path: "UBFoundationPush/Sources"),
        .target(name: "UBFoundationLocation", dependencies: ["UBFoundation"], path: "UBFoundationLocation/Sources"),
        .testTarget(name: "Tests", dependencies: ["UBFoundation"], path: "Tests"),
        .testTarget(name: "LocationTests", dependencies: ["UBFoundation", "UBFoundationLocation"], path: "UBFoundationLocation/Tests")
    ]
)
