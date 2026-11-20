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
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.5.0")
    ],
    targets: [
        .target(
            name: "RailXCore",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
        ),
        .testTarget(name: "RailXCoreTests", dependencies: ["RailXCore"])
    ]
)
