#!/bin/bash
# Publish the locally built iOS xcframework as a release on the engine fork,
# then print the two lines to update in Package.swift.
#
#   scripts/build-ios-audreborn.sh                        # compile
#   scripts/make-libgodot.xcframework . ../godot artifacts # package
#   scripts/publish-audreborn-release.sh v4.7.1-audreborn.2
#
# Upstream's Makefile refers to a `publish-libgodot-release` script that this
# fork does not carry, and its --zip path insists on a macOS xcframework we
# deliberately never build. Hence this one.
set -euo pipefail

VERSION="${1:-}"
[ -n "$VERSION" ] || { echo "usage: $(basename "$0") v4.7.1-audreborn.N" >&2; exit 1; }

REPO="${GODOT_REPO:-ZouAgTao/godot}"
BRANCH="${GODOT_BRANCH:-audreborn-4.7}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XC="$ROOT/artifacts/ios/libgodot.xcframework"
ZIP="$ROOT/artifacts/ios/libgodot-ios.xcframework.zip"

[ -d "$XC" ] || { echo "error: 没有 $XC —— 先构建再打包" >&2; exit 1; }

echo "打包 $VERSION …"
rm -f "$ZIP"
(cd "$(dirname "$XC")" && ditto -c -k --sequesterRsrc --keepParent \
    "$(basename "$XC")" "$(basename "$ZIP")")

SUM="$(cd "$ROOT" && swift package compute-checksum "$ZIP")"

gh release create "$VERSION" --repo "$REPO" --target "$BRANCH" \
    --title "libgodot ${VERSION#v} (iOS)" \
    --notes "iOS libgodot built from \`$BRANCH\`. Slices: ios-arm64 and ios-arm64_x86_64-simulator; no macOS slices.

\`\`\`
checksum: $SUM
\`\`\`" \
    "$ZIP"

cat <<MSG

把 Package.swift 里的 libgodotRelease 改成：

    version:  "$VERSION",
    checksum: "$SUM"

然后提交、推送，再把宿主工程的包引用指到新的 revision。
MSG
