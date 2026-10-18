// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "TrackpadPad",
    platforms: [.macOS("26.0")],
    targets: [
        .target(name: "CPrivate"),
        .executableTarget(name: "TrackpadPad", dependencies: ["CPrivate"]),
    ]
)
