// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ConnectedInsights",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "ConnectedInsights", targets: ["ConnectedInsights"]),
    ],
    targets: [
        .target(name: "ConnectedInsights"),
        .testTarget(name: "ConnectedInsightsTests", dependencies: ["ConnectedInsights"]),
    ],
    swiftLanguageModes: [.v6]
)
