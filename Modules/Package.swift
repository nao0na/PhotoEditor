// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Modules",
  platforms: [
    .iOS(.v14)
  ],
  products: [
    .library(
      name: "App",
      type: .static,
      targets: ["App"]
    ),
    .library(
      name: "WelcomeFeature",
      type: .static,
      targets: ["WelcomeFeature"]
    ),
    .library(
      name: "PhotoPickerFeature",
      type: .static,
      targets: ["PhotoPickerFeature"]
    ),
    .library(
      name: "EditorFeature",
      type: .static,
      targets: ["EditorFeature"]
    ),
    .library(
      name: "CanvasFeature",
      type: .static,
      targets: ["CanvasFeature"]
    ),
    .library(
      name: "ToolbarFeature",
      type: .static,
      targets: ["ToolbarFeature"]
    ),
  ],
  dependencies: [
    .package(path: "Core"),
    .package(path: "Dependencies"),
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        "Core",
        "WelcomeFeature",
        "PhotoPickerFeature",
        "EditorFeature",
        .product(
          name: "_Lottie",
          package: "Dependencies"
        )
      ],
      resources: [
        .process("Resources")
      ]
    ),
    .target(
      name: "WelcomeFeature",
      dependencies: [
        "Core",
        .product(
          name: "_Lottie",
          package: "Dependencies"
        )
      ],
      resources: [
        .process("Resources")
      ]
    ),
    .target(
      name: "PhotoPickerFeature",
      dependencies: [
        "Core",
      ]
    ),
    .target(
      name: "EditorFeature",
      dependencies: [
        "Core",
        "ToolbarFeature",
        "CanvasFeature",
        .product(
          name: "_Lottie",
          package: "Dependencies"
        )
      ]
    ),
    .target(
      name: "ToolbarFeature",
      dependencies: [
        "Core",
        .product(
          name: "_Lottie",
          package: "Dependencies"
        )
      ],
      resources: [
        .process("Resources")
      ]
    ),
    .target(
      name: "CanvasFeature",
      dependencies: [
        "Core",
        .product(
          name: "_Alloy",
          package: "Dependencies"
        )
      ]
    ),
  ]
)
