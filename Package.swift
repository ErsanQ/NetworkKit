// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetworkKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "NetworkKit",
            targets: ["NetworkKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NetworkKit",
            dependencies: [],
            path: "Sources/NetworkKit"),
        .testTarget(
            name: "NetworkKitTests",
            dependencies: ["NetworkKit"],
            path: "Tests/NetworkKitTests"),
    ]
)
