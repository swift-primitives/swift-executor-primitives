// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-executor-primitives",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(
            name: "Executor Primitive",
            targets: ["Executor Primitive"]
        ),
        .library(
            name: "Executor Job Primitives",
            targets: ["Executor Job Primitives"]
        ),
        .library(
            name: "Executor Shutdown Primitives",
            targets: ["Executor Shutdown Primitives"]
        ),
        .library(
            name: "Executor Wait Primitives",
            targets: ["Executor Wait Primitives"]
        ),

        .library(
            name: "Executor Job Queue Primitives",
            targets: ["Executor Job Queue Primitives"]
        ),
        .library(
            name: "Executor Job Deque Primitives",
            targets: ["Executor Job Deque Primitives"]
        ),

        .library(
            name: "Executor Primitives",
            targets: ["Executor Primitives"]
        ),
        .library(
            name: "Executor Primitives Test Support",
            targets: ["Executor Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-buffer-ring-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-clock-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-column-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-deque-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-index-primitives.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Executor Primitive",
            dependencies: []
        ),
        .target(
            name: "Executor Job Primitives",
            dependencies: [
                "Executor Primitive"
            ]
        ),
        .target(
            name: "Executor Shutdown Primitives",
            dependencies: [
                "Executor Primitive"
            ]
        ),
        .target(
            name: "Executor Wait Primitives",
            dependencies: [
                "Executor Primitive"
            ]
        ),

        .target(
            name: "Executor Job Queue Primitives",
            dependencies: [
                "Executor Job Primitives",
                .product(name: "Buffer Ring Primitive", package: "swift-buffer-ring-primitives"),
                .product(name: "Column Primitives", package: "swift-column-primitives"),
                .product(name: "Deque Primitives", package: "swift-deque-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),

        .target(
            name: "Executor Job Deque Primitives",
            dependencies: [
                "Executor Job Primitives",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),

        .target(
            name: "Executor Primitives",
            dependencies: [
                "Executor Primitive",
                "Executor Job Primitives",
                "Executor Shutdown Primitives",
                "Executor Wait Primitives",
                "Executor Job Queue Primitives",
                "Executor Job Deque Primitives",

            ]
        ),

        .target(
            name: "Executor Primitives Test Support",
            dependencies: [
                "Executor Primitives"
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Executor Primitives Tests",
            dependencies: [
                "Executor Primitives",
                "Executor Primitives Test Support",
                .product(name: "Clock Primitives", package: "swift-clock-primitives"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = [
        .define(
            "KERNEL_AVAILABLE",
            .when(platforms: [
                .macOS, .iOS, .tvOS, .watchOS, .visionOS,
                .linux, .windows, .android, .openbsd,
            ])
        )
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
