// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RailXCore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "RailXCore", targets: ["RailXCore"])
    ],
    targets: [
        .target(name: "RailXCore"),
        .testTarget(name: "RailXCoreTests", dependencies: ["RailXCore"])
    ]
)
