// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BEPlayer",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "BEPlayer",
            targets: ["BEPlayer"]
        ),
        .library(
            name: "BELoader",
            targets: ["BELoader"]
        ),
    ],
    targets: [
        // BEPlayer 模块
        .target(
            name: "BEPlayer",
            path: "Sources/BEPlayer",
            publicHeadersPath: "include" // Objective-C 头文件目录
        ),
        // BELoader 模块
        .target(
            name: "BELoader",
            path: "Sources/BELoader",
            publicHeadersPath: "include" // Objective-C 头文件目录
        )
    ]
)
