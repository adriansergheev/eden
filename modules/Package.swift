// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "eden-app",
  platforms: [.iOS(.v17)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "Cards", targets: ["Cards"]),
    .library(name: "StorageClient", targets: ["StorageClient"]),
    .library(name: "StorageClientLive", targets: ["StorageClientLive"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.0.6"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.3.9"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "Cards",
      dependencies: [
        "StorageClient",
        .product(name: "SwiftUINavigation", package: "swift-navigation"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections")
      ]
    ),
    .target(
      name: "StorageClient", dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "StorageClientLive", dependencies: [
        "StorageClient",
        .product(name: "Dependencies", package: "swift-dependencies")
      ]
    ),
    .testTarget(name: "CardsTests", dependencies: ["Cards"])
  ]
)
