// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "EyeYoga",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "EyeYogaCore"),
        .executableTarget(name: "EyeYoga", dependencies: ["EyeYogaCore"]),
        .testTarget(name: "EyeYogaCoreTests", dependencies: ["EyeYogaCore"]),
    ]
)
