// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NavigationHelper",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "NavigationHelper",
            targets: ["NavigationHelper"]),
        .library(
            name: "NavigationHelperUIKit",
            targets: ["NavigationHelperUIKit"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/facile-it/FunctionalKit.git", from: Version(0,23,0)),
        .package(url: "https://github.com/typelift/Abstract.git", from: Version(0,1,0)),
        .package(url: "https://gitlab.facile.it/mobile-apps/Log", from: Version(0,5,0)),
		.package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
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
