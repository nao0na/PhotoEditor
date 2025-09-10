// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Core",
  platforms: [
    .iOS(.v14)
  ],
  products: [
    .library(
      name: "Core",
      type: .static,
      targets: ["Core"]
    ),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "Core",
      dependencies: [],
      resources: [
        .process("Resources")
      ]
    ),
  ]
)
