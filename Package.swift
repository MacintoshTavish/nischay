// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Nischay",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Nischay",
            path: "Sources/Nischay",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
