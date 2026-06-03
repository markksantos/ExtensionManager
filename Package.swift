// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExtensionManager",
    platforms: [.macOS(.v13)],
    targets: [
         .executableTarget(
            name: "ExtensionManager",
            path: "Sources"
         ),
         .testTarget(
            name: "ExtensionManagerTests",
            dependencies: ["ExtensionManager"],
            path: "Tests/ExtensionManagerTests"
         ),
    ]
)
