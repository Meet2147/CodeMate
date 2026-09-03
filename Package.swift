// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CodeMate",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodeMate", targets: ["CodeMate"])
    ],
    targets: [
        .executableTarget(
            name: "CodeMate",
            path: "Sources/CodeMate"
        )
    ]
)
