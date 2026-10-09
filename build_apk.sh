#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export ANDROID_SDK_ROOT="/opt/homebrew/share/android-commandlinetools"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0:$PATH"

MODE="${1:---export-release}"

echo "Building Android APK (mode: $MODE)..."
mkdir -p build
godot --headless --path "$SCRIPT_DIR" "$MODE" Android build/arena_dash.apk

echo "Done! Output: $SCRIPT_DIR/build/arena_dash.apk"
ls -lh build/arena_dash.apk
