// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Nearby",
	 platforms: [
			  .macOS(.v11),
			  .iOS(.v14),
			  .watchOS(.v5)
		 ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Nearby",
            targets: ["Nearby"]),
    ],
    dependencies: [
		.package(url: "https://github.com/ios-tooling/crossplatformkit.git", from: "1.0.10"),
	   .package(url: "https://github.com/ios-tooling/suite.git", from: "1.0.108")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Nearby",
				dependencies: [
					.product(name: "Suite", package: "Suite"),
					.product(name: "CrossPlatformKit", package: "CrossPlatformKit"),
				]),
    ]
)
