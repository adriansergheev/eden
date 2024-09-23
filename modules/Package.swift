// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "eden-app",
  platforms: [.iOS(.v17)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "Content", targets: ["Content"])
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
      name: "Content",
      dependencies: [
        .product(name: "SwiftUINavigation", package: "swift-navigation"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections")
      ]
    ),
    .testTarget(name: "ContentTests", dependencies: ["Content"])
  ]
)
