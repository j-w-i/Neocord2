// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "SwiftcordLegacy",
    platforms: [
        .iOS("5.0")
    ],
    products: [
        .library(
            name: "SwiftcordLegacy",
            targets: ["SwiftcordLegacy"]
        ),
    ],
    dependencies: [
        .package(path: "../SocketRocket"),
        .package(path: "../NSJSONSerialization-for-Swift"),
    ],
    targets: [
        .target(
            name: "SwiftcordLegacy",
            dependencies: [
                .product(name: "SocketRocket", package: "SocketRocket"),
                .product(name: "NSJSONSerializationForSwift", package: "NSJSONSerialization-for-Swift"),
            ]
        ),
        .testTarget(
            name: "SwiftcordLegacyTests",
            dependencies: ["SwiftcordLegacy"]
        ),
    ]
)
