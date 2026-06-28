// swift-tools-version:5.9
//
//  Package.swift — Salvager
//
//  Builds the *platform-agnostic game logic* (Shared/Sources) as a library so
//  it can be compiled and unit-tested in CI without an Xcode project. The
//  watchOS/iOS app and widget targets still require an Xcode project (assembled
//  on a Mac — see README); this package covers the core that builds anywhere.
//

import PackageDescription

let package = Package(
    name: "Salvager",
    platforms: [
        .macOS(.v12),
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "SalvagerCore", targets: ["SalvagerCore"])
    ],
    targets: [
        .target(
            name: "SalvagerCore",
            path: "Shared/Sources"
        ),
        .testTarget(
            name: "SalvagerCoreTests",
            dependencies: ["SalvagerCore"],
            path: "Tests/SalvagerCoreTests"
        )
    ]
)
