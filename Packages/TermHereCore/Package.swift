// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TermHereCore",
    platforms: [.macOS(.v13)],
    products: [.library(name: "TermHereCore", targets: ["TermHereCore"])],
    targets: [
        .target(name: "TermHereCore"),
        .testTarget(name: "TermHereCoreTests", dependencies: ["TermHereCore"]),
    ]
)
