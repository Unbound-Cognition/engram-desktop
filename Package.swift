// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EngramDesktop",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Engram", targets: ["EngramDesktop"]),
    ],
    targets: [
        .executableTarget(
            name: "EngramDesktop",
            path: "Sources/EngramDesktop"
        ),
    ]
)
