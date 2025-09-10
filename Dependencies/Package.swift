// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Dependencies",
  platforms: [
    .iOS(.v14),
  ],
  products: [
    .library(
      name: "_Lottie",
      targets: ["_Lottie"]
    ),
    .library(
      name: "_Alloy",
      targets: ["_Alloy"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/airbnb/lottie-ios",
      .upToNextMinor(from: "3.4.4")
    ),
    .package(
      url: "https://github.com/s1ddok/Alloy.git",
      .upToNextMinor(from: "0.18.0")
    ),
  ],
  targets: [
    .target(
      name: "_Lottie",
      dependencies: [
        .product(
          name: "Lottie",
          package: "lottie-ios"
        )
      ]
    ),
    .target(
      name: "_Alloy",
      dependencies: [
        .product(
          name: "Alloy",
          package: "Alloy"
        ),
      ]
    )
  ]
)
