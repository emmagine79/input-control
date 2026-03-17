// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "InputControl",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "InputControl",
            targets: ["InputControl"]
        )
    ],
    targets: [
        .executableTarget(
            name: "InputControl",
            path: "Sources"
        )
    ]
)
