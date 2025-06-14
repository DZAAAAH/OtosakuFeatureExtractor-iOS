// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OtosakuFeatureExtractor",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OtosakuFeatureExtractor",
            targets: ["OtosakuFeatureExtractor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dhrebeniuk/plain-pocketfft.git", from: "0.0.9"),
        .package(url: "https://github.com/dhrebeniuk/pocketfft.git", from: "0.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OtosakuFeatureExtractor",
            dependencies: [
                .product(name: "PlainPocketFFT", package: "plain-pocketfft"),
                .product(name: "PocketFFT", package: "pocketfft")
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-enable-library-evolution"]),
                .define("BUILD_LIBRARY_FOR_DISTRIBUTION")
            ]
        ),
        .testTarget(
            name: "OtosakuFeatureExtractorTests",
            dependencies: ["OtosakuFeatureExtractor"]
        ),
    ]
)
