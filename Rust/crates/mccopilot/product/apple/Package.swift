// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MccopilotBridge",
    platforms: [
        .iOS(.v16),

    ],
    products: [
        .library(
            name: "MccopilotBridge",
            targets: ["MccopilotBridge"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "MccopilotBridgeFFI",
            path: "MccopilotBridge.xcframework"
        ),
        .target(
            name: "MccopilotBridge",
            dependencies: ["MccopilotBridgeFFI"],
            path: "Sources"
        ),
    ]
)
