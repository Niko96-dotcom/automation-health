// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AutomationHealth",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ActiveJobsCore", targets: ["ActiveJobsCore"]),
        .executable(name: "AutomationHealth", targets: ["AutomationHealth"]),
        .executable(name: "ActiveJobsCoreSelfTest", targets: ["ActiveJobsCoreSelfTest"])
    ],
    targets: [
        .target(name: "ActiveJobsCore"),
        .executableTarget(
            name: "AutomationHealth",
            dependencies: ["ActiveJobsCore"]
        ),
        .executableTarget(
            name: "ActiveJobsCoreSelfTest",
            dependencies: ["ActiveJobsCore"]
        )
    ]
)
