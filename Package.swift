// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FitTrack",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FitTrack",
            targets: ["FitTrack"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.14.0")
    ],
    targets: [
        .target(
            name: "FitTrack",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: ".",
            exclude: ["Tests", "Backend"],
            sources: [
                "App",
                "Configuration",
                "Core",
                "Models",
                "Services",
                "ViewModels",
                "Views"
            ],
            resources: [
                .process("Models/CoreData/FitTrack.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "FitTrackTests",
            dependencies: ["FitTrack"],
            path: "Tests/FitTrackTests"
        )
    ]
)
