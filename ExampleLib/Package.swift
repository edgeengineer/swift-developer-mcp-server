// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExampleLib",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ExampleLib",
            targets: ["ExampleLib"]
        ),
        .executable(
            name: "ExampleApp",
            targets: ["ExampleApp"]
        )
    ],
    dependencies: [
        // Swift Testing is built into Swift 6.1+
    ],
    targets: [
        .target(
            name: "ExampleLib",
            dependencies: []
        ),
        .executableTarget(
            name: "ExampleApp",
            dependencies: ["ExampleLib"]
        ),
        .testTarget(
            name: "ExampleLibTests",
            dependencies: ["ExampleLib"]
        )
    ]
)