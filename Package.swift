// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Nozzle",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "Nozzle",
            targets: ["Nozzle"]
        ),
    ],
    targets: [
        .target(
            name: "CNozzle",
            path: "Sources/CNozzle",
            publicHeadersPath: "include"
        ),
        .target(
            name: "Nozzle",
            dependencies: ["CNozzle"],
            linkerSettings: [
                .linkedLibrary("nozzle"),
                .linkedLibrary("c++"),
                .linkedFramework("Metal"),
                .linkedFramework("IOSurface"),
                .linkedFramework("Foundation"),
                .linkedFramework("OpenGL"),
                .linkedFramework("Accelerate"),
                .unsafeFlags(["-Ldeps/nozzle/build"]),
            ]
        ),
        .target(
            name: "ExamplePixels",
            dependencies: ["Nozzle"]
        ),
        .executableTarget(
            name: "SenderExample",
            dependencies: ["Nozzle", "ExamplePixels"],
            path: "Sources/Binaries/SenderExample",
            linkerSettings: [
                .linkedLibrary("nozzle"),
                .linkedLibrary("c++"),
                .linkedFramework("Metal"),
                .linkedFramework("IOSurface"),
                .linkedFramework("Foundation"),
                .linkedFramework("OpenGL"),
                .linkedFramework("Accelerate"),
                .unsafeFlags(["-Ldeps/nozzle/build"]),
            ]
        ),
        .executableTarget(
            name: "ReceiverExample",
            dependencies: ["Nozzle", "ExamplePixels"],
            path: "Sources/Binaries/ReceiverExample",
            linkerSettings: [
                .linkedLibrary("nozzle"),
                .linkedLibrary("c++"),
                .linkedFramework("Metal"),
                .linkedFramework("IOSurface"),
                .linkedFramework("Foundation"),
                .linkedFramework("OpenGL"),
                .linkedFramework("Accelerate"),
                .unsafeFlags(["-Ldeps/nozzle/build"]),
            ]
        ),
        .testTarget(
            name: "NozzleTests",
            dependencies: ["Nozzle", "CNozzle", "ExamplePixels"],
            linkerSettings: [
                .linkedLibrary("nozzle"),
                .linkedLibrary("c++"),
                .linkedFramework("Metal"),
                .linkedFramework("IOSurface"),
                .linkedFramework("Foundation"),
                .linkedFramework("OpenGL"),
                .linkedFramework("Accelerate"),
                .unsafeFlags(["-Ldeps/nozzle/build"]),
            ]
        ),
    ]
)
