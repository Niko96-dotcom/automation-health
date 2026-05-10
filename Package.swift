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
    targets: [
        .target(name: "ActiveJobsCore"),
        .target(
            name: "AutomationHealthCore",
            dependencies: ["ActiveJobsCore"]
        ),
        .executableTarget(
            name: "AutomationHealth",
            dependencies: ["ActiveJobsCore", "AutomationHealthCore"]
        ),
        .executableTarget(
            name: "ActiveJobsCoreSelfTest",
            dependencies: ["ActiveJobsCore", "AutomationHealthCore"]
        )
    ]
)
