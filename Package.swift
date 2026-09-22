// swift-tools-version: 5.9
import PackageDescription
import Foundation

// libgodot comes from our own fork of the engine (ZouAgTao/godot, branch
// `audreborn-4.7`). There are two ways to get it:
//
//   default           the published release named below. A fresh checkout builds
//                     with no engine toolchain and no godot checkout -- SwiftPM
//                     downloads and caches the xcframework.
//   LIBGODOT_LOCAL=1  artifacts/ios/libgodot.xcframework, built by
//                     scripts/build-ios-audreborn.sh. This is the mode for working
//                     ON the engine: about 30 seconds per round trip, and nothing
//                     goes over the network.
//
// After changing the engine, publish with scripts/publish-audreborn-release.sh --
// it prints the two lines to update right here.
//
// The macOS binary target upstream declares is dropped, along with the sample
// executable: this package is consumed by an iPhone-only host, and building the
// two macOS slices doubles the build time.
let libgodotRelease = (
    version: "v4.7.1-audreborn.1",
    checksum: "fcff4e9367c8f747e7540926bc625293e7d298955a12daa0a603cca251182720"
)

let iosLibgodotTarget: Target =
    ProcessInfo.processInfo.environment["LIBGODOT_LOCAL"] != nil
    ? .binaryTarget(
        name: "ios_libgodot",
        path: "artifacts/ios/libgodot.xcframework"
      )
    : .binaryTarget(
        name: "ios_libgodot",
        url: "https://github.com/ZouAgTao/godot/releases/download/"
             + "\(libgodotRelease.version)/libgodot-ios.xcframework.zip",
        checksum: libgodotRelease.checksum
      )

let package = Package(
    name: "SwiftGodotKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftGodotKit",
            targets: ["SwiftGodotKit"]),
    ],
    dependencies: [
    		  // This is tag 0.75.0
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "48112dd50fffe01f0af78e445a16991ecdc6bc94"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftGodotKit",
            dependencies: [
                "SwiftGodot",
                "libgodot",
                .target(name: "apple_plugin_stubs", condition: .when(platforms: [.iOS])),
                .target(name: "ios_libgodot", condition: .when(platforms: [.iOS])),
            ]
        ),

        .target(
            name: "apple_plugin_stubs",
            path: "Sources/apple_plugin_stubs",
            publicHeadersPath: "include"
        ),

        iosLibgodotTarget,
        .systemLibrary(
            name: "libgodot"
        ),
    ]
)
