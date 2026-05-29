// swift-tools-version:5.9
import PackageDescription

// Provided so the source can be inspected / built/tested as a library on a Mac.
// The shipping application is the Xcode project (Svatek.xcodeproj). SwiftPM cannot
// produce a macOS .app bundle with Info.plist + resources on its own.
let package = Package(
    name: "Svatek",
    defaultLocalization: "cs",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "SvatekCore", targets: ["SvatekCore"]),
    ],
    targets: [
        .target(
            name: "SvatekCore",
            path: "Svatek",
            exclude: ["Resources/Info.plist"],
            sources: ["Sources"],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
