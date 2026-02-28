// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PrivacyScreen",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PrivacyScreen",
            targets: ["PrivacyScreen"]
        )
    ],
    targets: [
        .target(
            name: "PrivacyScreen",
            path: "Sources/PrivacyScreen"
        ),
        .testTarget(
            name: "PrivacyScreenTests",
            dependencies: ["PrivacyScreen"],
            path: "Tests/PrivacyScreenTests"
        )
    ]
)
