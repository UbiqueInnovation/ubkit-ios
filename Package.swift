// swift-tools-version:5.0
//
//  UBFoundation


import PackageDescription

let package = Package(
    name: "UBFoundation",
    products: [
        .library(name: "UBFoundation", targets: ["UBFoundation"]),
    ],
    targets: [
        .target(name: "UBFoundation", path: "Sources"),
		.testTarget(name: "Tests", dependencies: ["UBFoundation"], path: "Tests"),
    ]
)
