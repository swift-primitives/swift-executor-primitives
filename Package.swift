// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-executor-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        // MARK: - Namespace
        .library(
            name: "Executor Primitive",
            targets: ["Executor Primitive"]
        ),
        // MARK: - Umbrella
        .library(
            name: "Executor Primitives",
            targets: ["Executor Primitives"]
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
            name: "Executor Job Priority Primitives",
            targets: ["Executor Job Priority Primitives"]
        ),
        .library(
            name: "Executor Primitives Test Support",
            targets: ["Executor Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-queue-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-deque-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-heap-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-clock-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-comparison-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Namespace
        .target(
            name: "Executor Primitive",
            dependencies: []
        ),

        // MARK: - Core
        .target(
            name: "Executor Primitives Core",
            dependencies: [
                "Executor Primitive",
            ]
        ),

        // MARK: - Job Queue
        .target(
            name: "Executor Job Queue Primitives",
            dependencies: [
                "Executor Primitives Core",
                .product(name: "Queue DoubleEnded Primitives", package: "swift-deque-primitives"),
                .product(name: "Queue Primitives Core", package: "swift-queue-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),

        // MARK: - Job Deque
        .target(
            name: "Executor Job Deque Primitives",
            dependencies: [
                "Executor Primitives Core",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Inline Primitives", package: "swift-memory-primitives"),
            ]
        ),

        // MARK: - Job Priority
        .target(
            name: "Executor Job Priority Primitives",
            dependencies: [
                "Executor Primitives Core",
                .product(name: "Heap Primitives Core", package: "swift-heap-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Comparison Primitives", package: "swift-comparison-primitives"),
                .product(name: "Clock Primitives", package: "swift-clock-primitives"),
            ]
        ),

        // MARK: - Umbrella
        .target(
            name: "Executor Primitives",
            dependencies: [
                "Executor Primitive",
                "Executor Primitives Core",
                "Executor Job Queue Primitives",
                "Executor Job Deque Primitives",
                "Executor Job Priority Primitives",
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "Executor Primitives Test Support",
            dependencies: [
                "Executor Primitives",
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
        .testTarget(
            name: "Executor Primitives Tests",
            dependencies: [
                "Executor Primitives",
                "Executor Primitives Test Support",
                .product(name: "Clock Primitives", package: "swift-clock-primitives"),
            ]
        )
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = [
        .define("KERNEL_AVAILABLE", .when(platforms: [
            .macOS, .iOS, .tvOS, .watchOS, .visionOS,
            .linux, .windows, .android, .openbsd,
        ])),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
