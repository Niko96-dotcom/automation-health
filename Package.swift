// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AutomationHealth",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ActiveJobsCore", targets: ["ActiveJobsCore"]),
        .library(name: "AutomationHealthCore", targets: ["AutomationHealthCore"]),
        .executable(name: "AutomationHealth", targets: ["AutomationHealth"]),
        .executable(name: "ActiveJobsCoreSelfTest", targets: ["ActiveJobsCoreSelfTest"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.1")
    ],
    targets: [
        .target(name: "ActiveJobsCore"),
        .target(
            name: "AutomationHealthCore",
            dependencies: ["ActiveJobsCore"]
        ),
        .executableTarget(
            name: "AutomationHealth",
            dependencies: ["ActiveJobsCore", "AutomationHealthCore", "Sparkle"]
        ),
        .executableTarget(
            name: "ActiveJobsCoreSelfTest",
            dependencies: ["ActiveJobsCore", "AutomationHealthCore"]
        )
    ]
)
