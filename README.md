# SwiftGodotKit — Rooftop Station fork

This fork embeds Godot into the SwiftUI iPhone app **Rooftop Station**. It builds
on [SwiftGodotKit](https://github.com/migueldeicaza/SwiftGodotKit) and uses
[SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) for the Swift API bindings.
Development conventions and handoff notes are in [AGENTS.md](AGENTS.md).

## Repositories and compatibility

| Repository | Integration branch | Responsibility |
| --- | --- | --- |
| `ZouAgTao/SwiftGodotKit` | `audreborn` | Swift embedding, view lifecycle, message bridge, frame loop, build and packaging scripts |
| `ZouAgTao/godot` | `audreborn-4.7` | libgodot engine source and host-specific engine patches |
| `ZouAgTao/RooftopStation` | App-owned branches | SwiftUI host, application behavior, scenes and resources |

The local checkouts are siblings:

```text
Ability/
├── SwiftGodotKit/
├── godot/
├── RooftopStation/
├── .venv-godot/       SCons environment
└── build-logs/        Local engine build logs
```

The engine fork is based on the community libgodot 4.7 commit `30aca496`.
`Package.swift` pins the compatible SwiftGodot revision and the published engine
version/checksum. Keep the Swift bindings and engine API compatible; changing one
independently can cause method-bind failures at runtime.

This fork currently supplies **iOS engine binaries only**, containing arm64 device
and arm64/x86_64 simulator slices. The manifest still lists macOS and the source
tree retains upstream macOS examples, but there is no macOS binary target here.
Simulator slices support native integration work; Godot's Metal rendering is not
validated there. Check visuals, frame cadence and audio behavior on an iPhone.

## Use in an app

Add `https://github.com/ZouAgTao/SwiftGodotKit` through Xcode or SwiftPM, pin a
tested revision, and depend on the `SwiftGodotKit` product. SwiftPM downloads the
iOS xcframework from the engine fork's release automatically. App developers do
not need a local engine checkout or SCons.

```swift
import SwiftUI
import SwiftGodotKit

struct ContentView: View {
    @State private var app = GodotApp(packFile: "game.pck")

    var body: some View {
        GodotAppView()
            .environment(\.godotApp, app)
    }
}
```

Use one `GodotApp` per application. Rooftop Station keeps its embedded view alive
and changes the scene's state through the host bridge. Its `.pck` contains scene
resources; the engine comes from the xcframework.

## Host-specific behavior

- The iOS display link uses the main run loop's `.common` mode so Godot continues
  iterating during scrolling and sheet drags. iOS still stops display-link
  callbacks in the background; the engine audio thread can continue mixing.
- `GodotApp.setPreferredFrameRate(_:)` and
  `GodotAppViewHandle.setPreferredFrameRate(_:)` request an iOS frame cadence,
  clamped to 1...60 fps, with a default of 60. The request is applied on the main
  thread without replacing the view. Hardware and power policies can lower the
  actual cadence. The host decides when to lower or restore the rate.
- The engine fork exposes `AudioServer.restart_output_driver()` to rebuild audio
  output after interruptions or route changes, and `stop_output_driver()` to keep
  output stopped while the host cycles its audio session. These are engine
  patches, separate from this package's Swift source. Standard Godot editors lack
  the methods, so GDScript callers use `has_method` and dynamic calls.

## Work on the Swift embedding layer

Override the host's remote SwiftGodotKit dependency with this local package in
Xcode. This selects local **Swift source**; it does not automatically select a
locally built engine. Swift-only changes can use the published engine binary and
do not require an engine rebuild or a new binary release.

For Rooftop Station integration, run from its checkout:

```sh
tools/verify_ios.sh
```

This builds the iPhone configuration without signing and checks key settings in
the built app. It does not validate device behavior. The host also has native
frame-rate policy checks:

```sh
cd ios
swift test -c release --filter FrameRatePolicyTests
```

## Build and consume a local engine

Prerequisites are Xcode command-line tools, the sibling `godot` checkout, and
SCons. The existing workspace uses `../.venv-godot/bin/scons`.

From this repository's root:

```sh
scripts/build-ios-audreborn.sh
scripts/make-libgodot.xcframework . ../godot artifacts
```

The build helper produces all three iOS `template_release` archives with Metal
enabled and Vulkan disabled. It accepts `GODOT`, `SCONS`, `LOGDIR`, `JOBS` and
`TARGET` environment overrides, records per-slice logs and returns failure if any
slice fails. The packaging script combines the archives into
`artifacts/ios/libgodot.xcframework`. Its first positional argument is retained
from upstream; `.` is sufficient for this iOS packaging flow. Missing macOS
libraries are reported and do not prevent iOS packaging.

If building `TARGET=template_debug`, also pass `--configuration debug` to the
packaging script so it selects the debug archives.

To consume the local engine, set `LIBGODOT_LOCAL=1` in the environment that
evaluates `Package.swift` when Xcode/SwiftPM resolves the dependency, and ensure
the host references this local Swift package. Check the resolved xcframework
path to confirm the switch took effect. It should point inside this repository's
`artifacts/`, rather than the host's downloaded package artifacts.

The manifest checks whether the variable **exists**, so `LIBGODOT_LOCAL=0` also
selects the local engine. Unset it to return to the published release. Local Swift
package selection and local engine selection are independent settings.

`artifacts/` and engine libraries are ignored by Git. Do not commit the large
binaries or modify Xcode's downloaded package checkout to test source changes.

## Publish an engine change

Publish only after the engine source has been committed, pushed and validated.
From this repository's root, after building and packaging:

```sh
scripts/publish-audreborn-release.sh <new-version-tag>
```

The helper defaults to `ZouAgTao/godot` and `audreborn-4.7`; `GODOT_REPO` and
`GODOT_BRANCH` override those values. It requires authenticated `gh` access,
creates the iOS zip, computes its SwiftPM checksum, publishes a GitHub release,
and prints the version/checksum to put in `Package.swift`.

1. Use a new tag for every engine payload. Do not replace assets under an
   existing tag: SwiftPM can retain cached artifacts or report checksum errors.
2. Update `libgodotRelease` in `Package.swift`, then commit and push this package.
3. Update the host's fixed SwiftGodotKit revision and verify the app against it.

The upstream `scripts/Makefile` remains for reference. Its release targets expect
macOS builds and a publish helper absent from this fork. Use the iOS commands
above for this project's builds and releases.

## Upstream examples and license

`Sources/TrivialSample` and `StandaloneExample` preserve upstream examples. They
are outside the current iPhone delivery flow. For upstream API discussion, see
[SwiftGodot discussions](https://github.com/migueldeicaza/SwiftGodot/discussions).

This fork retains the upstream [MIT license](LICENSE).
