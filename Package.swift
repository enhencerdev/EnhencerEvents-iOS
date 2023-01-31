// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EnhencerEvents",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "EnhencerEvents",
            targets: ["EnhencerEvents"]),
    ],
    dependencies: [
        .package(url: "https://github.com/facebook/facebook-ios-sdk.git", from: "12.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "9.0.0"),
        
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "EnhencerEvents",
            dependencies: [
                .product(name: "FacebookCore", package: "facebook-ios-sdk"),
            ]),
        /*.testTarget(
            name: "ios_collectorTests",
            dependencies: ["ios_collector"]),*/
    ]
)
