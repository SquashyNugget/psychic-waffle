// swift-tools-version:5.9
import PackageDescription

// Optional: lets the pure timer engine be tested on Windows (Swift) or Linux.
// The iOS application itself is built using the project.yml/Xcode project.
let package = Package(
    name: "BadmintonTimerLogic",
    products: [
        .library(name: "BadmintonTimerLogic", targets: ["BadmintonTimerLogic"])
    ],
    targets: [
        .target(name: "BadmintonTimerLogic", path: "Core"),
        .testTarget(name: "BadmintonTimerLogicTests",
                    dependencies: ["BadmintonTimerLogic"], path: "Tests")
    ]
)
