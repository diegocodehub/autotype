// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "autotype",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "autotype", targets: ["autotype"]),
        .executable(name: "AutoTypeDesktop", targets: ["AutoTypeApp"])
    ],
    targets: [
        .target(name: "AutoTypeCore"),
        .executableTarget(name: "autotype", dependencies: ["AutoTypeCore"]),
        .executableTarget(name: "AutoTypeApp", dependencies: ["AutoTypeCore"]),
        .testTarget(name: "AutoTypeCoreTests", dependencies: ["AutoTypeCore"])
    ]
)
