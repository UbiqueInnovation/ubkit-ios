// swift-tools-version:5.6
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
        .plugin(name: "FormatSwift", targets: ["FormatSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.5.0"),
    ],
    targets: [
        .target(name: "UBFoundation"),
        .target(name: "UBUserInterface", dependencies: ["UBFoundation"]),
        .target(name: "UBLocation", dependencies: ["UBFoundation"]),
        .target(name: "UBPush", dependencies: ["UBFoundation"]),
        .target(name: "UBQRScanner"),
        .testTarget(name: "UBFoundationTests",
                    dependencies: ["UBFoundation"],
                    resources: [
                        .copy("TestResources"),
                    ]),
        .testTarget(name: "UBUserInterfaceTests",
                    dependencies: ["UBUserInterface"]),
        .testTarget(name: "UBLocationTests",
                    dependencies: ["UBLocation"]),
        .plugin(
            name: "FormatSwift",
            capability: .command(
                intent: .custom(
                    verb: "format",
                    description: "Formats Swift source files according to the Ubique Swift Style Guide"),
                permissions: [
                    .writeToPackageDirectory(reason: "Format Swift source files"),
                ]),
            dependencies: [
                "UBSwiftFormatTool",
                "SwiftFormat",
            ]),

            .executableTarget(
                name: "UBSwiftFormatTool",
                dependencies: [
                    .product(name: "ArgumentParser", package: "swift-argument-parser"),
                ],
                resources: [
                    .process("UB.swiftformat"),
                ]),

            .binaryTarget(
                name: "SwiftFormat",
                url: "https://github.com/calda/SwiftFormat/releases/download/0.50-beta-2/SwiftFormat.artifactbundle.zip",
                checksum: "8b96c5237d47b398f3eda215713ee164bc28556ef849a73a32995dcc4f12d702"),
    ]
)
