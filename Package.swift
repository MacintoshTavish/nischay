// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Nischay",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Nischay",
            path: "Sources/Nischay",
            exclude: [
                "Resources/Info.plist",
                "Resources/Nischay.entitlements"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "NischayTests",
            dependencies: ["Nischay"],
            path: "Tests/NischayTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
