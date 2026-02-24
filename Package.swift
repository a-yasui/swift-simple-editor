// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SimpleEditor",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "SimpleEditor",
            path: "Sources/SimpleEditor"
        )
    ]
)
