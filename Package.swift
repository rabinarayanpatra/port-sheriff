// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PortSheriff",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "PortSheriffKit",
            path: "Sources/PortSheriffKit"
        ),
        .executableTarget(
            name: "PortSheriff",
            dependencies: ["PortSheriffKit"],
            path: "Sources/PortSheriff"
        ),
        .testTarget(
            name: "PortSheriffTests",
            dependencies: [
                "PortSheriffKit",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/PortSheriffTests"
        ),
    ]
)
