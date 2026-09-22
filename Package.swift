// swift-tools-version: 5.9
import PackageDescription

// The libgodot binary is built locally from the adjacent `godot` checkout
// (branch `audreborn-4.7`) rather than downloaded from a release:
//
//   scripts/build-ios-audreborn.sh                       # 3 iOS slices, ~5 min
//   scripts/make-libgodot.xcframework . ../godot artifacts
//
// That keeps engine changes to a single local rebuild, with no release upload
// and no download on the way back. `artifacts/` is deliberately not in git --
// the xcframework is ~500 MB.
//
// The macOS binary target upstream declares is dropped: the host app is
// iPhone-only, and building the two macOS slices doubles the build time.
let iosLibgodotTarget: Target = .binaryTarget(
    name: "ios_libgodot",
    path: "artifacts/ios/libgodot.xcframework"
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
