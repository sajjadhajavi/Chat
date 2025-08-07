// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Chat",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ExyteChat",
            targets: ["ExyteChat"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/sajjadhajavi/MediaPicker",
            branch: "main"
        ),
        .package(
            url: "https://github.com/sajjadhajavi/SHAssetToolkit",
            branch: "main"
        ),
        .package(
            url: "https://github.com/exyte/ActivityIndicatorView",
            from: "1.0.0"
        ),
        .package(
           url: "https://github.com/Giphy/giphy-ios-sdk",
           from: "2.2.16"
        ),
    ],
    targets: [
        .target(
            name: "ExyteChat",
            dependencies: [
                .product(name: "ExyteMediaPicker", package: "MediaPicker"),
                .product(name: "SHAssetToolkit", package: "SHAssetToolkit"),
                .product(name: "ActivityIndicatorView", package: "ActivityIndicatorView"),
                .product(name: "GiphyUISDK", package: "giphy-ios-sdk")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ExyteChatTests",
            dependencies: ["ExyteChat"]),
    ]
)
