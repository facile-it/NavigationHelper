// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NavigationHelper",
    products: [
        .library(
            name: "NavigationHelper",
            targets: ["NavigationHelper"]),
        .library(
            name: "NavigationHelperUIKit",
            targets: ["NavigationHelperUIKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/facile-it/FunctionalKit.git", from: Version(0,23,0)),
        .package(url: "https://github.com/typelift/Abstract.git", from: Version(0,1,0)),
        .package(url: "https://gitlab.facile.it/mobile-apps/Log", from: Version(0,5,0)),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: Version(6,0,0))
    ],
    targets: [
        .target(
            name: "NavigationHelper",
            dependencies: [
                "FunctionalKit",
                "Abstract",
                "Log",
                "RxSwift"
            ]),
        .target(
            name: "NavigationHelperUIKit",
            dependencies: [
                "FunctionalKit",
                "Abstract",
                "Log",
                "RxSwift",
                "NavigationHelper"
            ]),
        .testTarget(
            name: "NavigationHelperTests",
            dependencies: ["NavigationHelper"]),
    ]
)
