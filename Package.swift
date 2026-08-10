// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorBrazePlugin",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapacitorBrazePlugin",
            targets: ["BrazePlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        // Braze iOS SDK (BrazeKit). To upgrade, bump the version below and
        // check https://github.com/braze-inc/braze-swift-sdk/releases for
        // breaking changes.
        .package(url: "https://github.com/braze-inc/braze-swift-sdk", from: "18.0.0")
    ],
    targets: [
        .target(
            name: "BrazePlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "BrazeKit", package: "braze-swift-sdk")
            ],
            path: "ios/Sources/BrazePlugin"),
        .testTarget(
            name: "BrazePluginTests",
            dependencies: ["BrazePlugin"],
            path: "ios/Tests/BrazePluginTests")
    ]
)