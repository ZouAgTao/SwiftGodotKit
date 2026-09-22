#!/bin/bash
# Build the three iOS libgodot slices needed by the audreborn host app.
#
# Deliberately skips the two macOS slices that make-libgodot.xcframework also
# builds: the host app is iPhone-only, and dropping them halves the wall time.
# make-libgodot.xcframework packages whatever is in bin/, and simply reports the
# macOS dylibs as missing, so packaging still works.
set -uo pipefail

GODOT="${GODOT:-/Users/agtao/Develop/Ability/godot}"
SCONS="${SCONS:-/Users/agtao/Develop/Ability/.venv-godot/bin/scons}"
LOGDIR="${LOGDIR:-$GODOT/../build-logs}"
JOBS="${JOBS:-$(sysctl -n hw.ncpu)}"
TARGET="${TARGET:-template_release}"

mkdir -p "$LOGDIR"
cd "$GODOT" || exit 1

fail=0
for slice in "arm64:no" "arm64:yes" "x86_64:yes"; do
    arch="${slice%%:*}"
    sim="${slice##*:}"
    name="ios-$arch-sim-$sim"
    printf '[%s] %-20s 开始\n' "$(date +%H:%M:%S)" "$name"
    start=$SECONDS
    "$SCONS" platform=ios "arch=$arch" "simulator=$sim" "target=$TARGET" \
        vulkan=no metal=yes disable_path_overrides=no "-j$JOBS" \
        > "$LOGDIR/$name.log" 2>&1
    code=$?
    printf '[%s] %-20s 结束 exit=%d 用时=%ds\n' \
        "$(date +%H:%M:%S)" "$name" "$code" "$((SECONDS - start))"
    [ $code -ne 0 ] && fail=1
done

echo "--- bin/ ---"
ls -lh bin/ 2>/dev/null | grep -v '^total'
exit $fail
