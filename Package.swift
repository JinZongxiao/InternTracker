// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InternTracker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "InternTracker", targets: ["InternTracker"])
    ],
    targets: [
        .executableTarget(
            name: "InternTracker",
            path: "Sources"
        )
    ]
)
