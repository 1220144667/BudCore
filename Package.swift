// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BudCore",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BudCore",
            targets: ["BudCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/1220144667/BudCommon.git", branch: "developer"),
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.27.1"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", exact: "0.13.3"),
        .package(url: "https://github.com/jrendel/SwiftKeychainWrapper.git", exact: "4.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BudCore", dependencies: [.common, .protobuf, .sqlite, .keychain]),
        .testTarget(
            name: "BudCoreTests",
            dependencies: ["BudCore", .common, .protobuf, .sqlite, .keychain]),
    ])

extension Target.Dependency {
    static let common = Self.product(name: "BudCommon", package: "BudCommon")
    static let protobuf = Self.product(name: "SwiftProtobuf", package: "swift-protobuf")
    static let sqlite = Self.product(name: "SQLite", package: "SQLite.swift")
    static let keychain = Self.product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper")
}
