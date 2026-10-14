#!/usr/bin/env bash
set +x  # Signing secrets must never be exposed by inherited shell tracing.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    echo "Usage: $0 [debug|release] [output.apk]"
    echo "Default: production signed release APK at build/arena_dash_release.apk."
    echo "Release uses the configured macOS Keychain identity automatically; secure GODOT_ANDROID_KEYSTORE_RELEASE_* overrides remain available for CI."
}
if [ "$#" -gt 2 ]; then usage >&2; exit 2; fi
case "${1:-release}" in
    -h|--help) usage; exit 0 ;;
    --export-release|release|--release) MODE="--export-release"; DEFAULT_OUTPUT="build/arena_dash_release.apk" ;;
    --export-debug|debug|--debug) MODE="--export-debug"; DEFAULT_OUTPUT="build/arena_dash_debug.apk" ;;
    *) usage >&2; exit 2 ;;
esac
OUTPUT_FILE="${2:-$DEFAULT_OUTPUT}"
case "$OUTPUT_FILE" in *.apk) ;; *) echo "Error: output must end in .apk." >&2; exit 2 ;; esac
case "$OUTPUT_FILE" in /*) ;; *) OUTPUT_FILE="$SCRIPT_DIR/$OUTPUT_FILE" ;; esac
python3 - "$SCRIPT_DIR" "$OUTPUT_FILE" <<'PY'
import sys
from pathlib import Path
build = (Path(sys.argv[1]) / 'build').resolve()
output = Path(sys.argv[2]).resolve()
if build in output.parents and output.parent != build:
    raise SystemExit("Keep build/ APK-only: use qa/ for nested diagnostic output")
PY

# Detect JAVA_HOME if not already configured or invalid
if [ -z "${JAVA_HOME:-}" ] || [ ! -x "${JAVA_HOME}/bin/java" ]; then
    if [ -x "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java" ]; then
        export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
    elif [ -x "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home/bin/java" ]; then
        export JAVA_HOME="/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
    elif command -v /usr/libexec/java_home >/dev/null 2>&1; then
        export JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null || /usr/libexec/java_home 2>/dev/null || true)"
    fi
fi

# Detect ANDROID_HOME / ANDROID_SDK_ROOT
if [ -n "${ANDROID_SDK_ROOT:-}" ] && [ -d "$ANDROID_SDK_ROOT/platform-tools" ]; then
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
elif [ -z "${ANDROID_HOME:-}" ] || [ ! -d "${ANDROID_HOME}" ]; then
    if [ -d "/opt/homebrew/share/android-commandlinetools/build-tools" ]; then
        export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
    fi
    if [ -d "$HOME/Library/Android/sdk/build-tools" ]; then
        export ANDROID_HOME="$HOME/Library/Android/sdk"
    fi
fi
export ANDROID_SDK_ROOT="${ANDROID_HOME:-}"
if [ ! -d "$ANDROID_SDK_ROOT/build-tools" ]; then
    echo "Error: Android SDK not found. Set ANDROID_SDK_ROOT to your SDK directory." >&2
    exit 1
fi

# Resolve build-tools directory
BUILD_TOOLS_BIN=""
if [ -n "${ANDROID_HOME:-}" ] && [ -d "${ANDROID_HOME}/build-tools" ]; then
    # Numeric versions without GNU sort -V (not available on every macOS host).
    LATEST_BUILD_TOOLS=$(find "$ANDROID_HOME/build-tools" -mindepth 1 -maxdepth 1 -type d | \
        awk -F/ '{print $NF " " $0}' | sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1 | cut -d' ' -f2-)
    if [ -n "$LATEST_BUILD_TOOLS" ]; then
        BUILD_TOOLS_BIN="$LATEST_BUILD_TOOLS"
    fi
fi

# Update PATH with Java and Android tools
[ -n "${JAVA_HOME:-}" ] && export PATH="${JAVA_HOME}/bin:${PATH}"
[ -n "${ANDROID_HOME:-}" ] && export PATH="${ANDROID_HOME}/platform-tools:${PATH}"
[ -n "${BUILD_TOOLS_BIN:-}" ] && export PATH="${BUILD_TOOLS_BIN}:${PATH}"

# Allow a specific Godot binary, then resolve the usual CLI or macOS app.
GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
if [ -z "$GODOT_BIN" ] && [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
    GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
fi
if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
    echo "Error: 'godot' command not found on PATH." >&2
    exit 1
fi
export PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}"
for TOOL in java keytool apksigner zipalign aapt apkanalyzer shasum python3; do
    if ! command -v "$TOOL" >/dev/null 2>&1; then
        echo "Error: required build tool '$TOOL' is unavailable." >&2; exit 1
    fi
done

# Release credentials stay outside the project. Resolve the configured Keychain
# identity when no CI environment override is present; never generate keys here.
if [ "$MODE" = "--export-release" ] && [ -z "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}${GODOT_ANDROID_KEYSTORE_RELEASE_USER:-}${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:-}" ]; then
    exec python3 "$SCRIPT_DIR/tools/android_signing.py" build "$@"
fi
if [ "$MODE" = "--export-release" ]; then
    if [ -z "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ] || [ -z "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:-}" ] || [ -z "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:-}" ]; then
        echo "Release blocked: set GODOT_ANDROID_KEYSTORE_RELEASE_PATH, GODOT_ANDROID_KEYSTORE_RELEASE_USER and GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD for your production key. A debug key is not a production key." >&2
        exit 1
    fi
    if [ ! -f "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" ]; then
        echo "Release blocked: production keystore file does not exist." >&2; exit 1
    fi
    if [ "$GODOT_ANDROID_KEYSTORE_RELEASE_USER" = "androiddebugkey" ] || [ "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" -ef "$SCRIPT_DIR/debug.keystore" ]; then
        echo "Release blocked: development debug keystore/alias selected." >&2; exit 1
    fi
    # Never place the password on the command line or print it.
    CERT_DETAILS=$(keytool -J-Duser.language=en -J-Duser.country=US -list -v -keystore "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" \
        -alias "$GODOT_ANDROID_KEYSTORE_RELEASE_USER" \
        -storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD 2>/dev/null) || {
        echo "Release blocked: keystore or alias could not be validated." >&2; exit 1;
    }
    if [[ "$CERT_DETAILS" == *"CN=Android Debug"* ]] || [[ "$CERT_DETAILS" != *"PrivateKeyEntry"* ]]; then
        echo "Release blocked: alias must contain a production private key, not an Android Debug certificate." >&2; exit 1
    fi
    EXPECTED_CERT_SHA256=$(printf "%s\n" "$CERT_DETAILS" | awk '/SHA256:/ {gsub(":", "", $2); print tolower($2); exit}')
    if [ -z "$EXPECTED_CERT_SHA256" ]; then echo "Release blocked: cannot identify production certificate." >&2; exit 1; fi
    if [ -n "${ARENA_ANDROID_EXPECTED_CERT_SHA256:-}" ] && [ "$EXPECTED_CERT_SHA256" != "$ARENA_ANDROID_EXPECTED_CERT_SHA256" ]; then
        echo "Release blocked: production certificate differs from the recorded signing identity." >&2; exit 1
    fi
    # A CI override must preserve the same published key as local Keychain builds.
    python3 tools/android_release_policy.py --certificate "$EXPECTED_CERT_SHA256"
    unset CERT_DETAILS
else
    if [ ! -f "debug.keystore" ]; then
        echo "Debug build blocked: existing debug.keystore is missing. Restore the original key to preserve update identity." >&2
        exit 1
    fi
fi
# Keep the preset's existing template identity. The project template links point
# to the installed exact-version templates; never fall back to another version.

echo "Godot: $("$GODOT_BIN" --version)"
echo "Building Android APK (mode: $MODE, output: $OUTPUT_FILE)..."
mkdir -p "$(dirname "$OUTPUT_FILE")"
# Export to a fresh directory: an old APK can never masquerade as a successful build.
# Keep the previous deliverable until the new artifact passes verification.
BUILD_STAGE=$(mktemp -d "${TMPDIR:-/tmp}/arena-build.XXXXXX")
trap 'rm -rf "$BUILD_STAGE"' EXIT
mkdir -p qa/build-verification
# Regenerate both adaptive layers and legacy icons from the provided vector
# artwork on every build so edited source artwork cannot leave stale icons.
"$GODOT_BIN" --headless --path "$SCRIPT_DIR" --log-file "$BUILD_STAGE/icons.log" --script res://tools/generate_android_icons.gd
# The supplied SVG uses Gaussian filters that need librsvg for transparent layers.
ICON_NODE_BIN="${ARENA_ICON_NODE_BIN:-$(command -v node || true)}"
if [ -z "$ICON_NODE_BIN" ]; then ICON_NODE_BIN="$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node"; fi
if [ ! -x "$ICON_NODE_BIN" ]; then echo "Build blocked: Node.js and sharp are required to render the supplied SVG filters." >&2; exit 1; fi
export ARENA_ICON_NODE_BIN="$ICON_NODE_BIN"
"$ICON_NODE_BIN" tools/render_android_icons.cjs

"$GODOT_BIN" --headless --path "$SCRIPT_DIR" --log-file "$BUILD_STAGE/export.log" "$MODE" Android "$BUILD_STAGE/arena_dash.apk"
if [ ! -s "$BUILD_STAGE/arena_dash.apk" ]; then
    echo "Error: Godot did not produce a new APK." >&2; exit 1
fi
echo "Verifying APK signature and alignment..."
apksigner verify --verbose --print-certs "$BUILD_STAGE/arena_dash.apk" > "$BUILD_STAGE/signature.txt"
cat "$BUILD_STAGE/signature.txt"
zipalign -c -P 16 4 "$BUILD_STAGE/arena_dash.apk"
python3 - "$BUILD_STAGE/arena_dash.apk" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as apk:
    bad = apk.testzip()
    if bad:
        raise SystemExit("APK ZIP integrity failure: " + bad)
    if 'AndroidManifest.xml' not in apk.namelist() or not any(n.startswith('lib/arm64-v8a/') for n in apk.namelist()):
        raise SystemExit("APK is missing manifest or arm64 libraries")
PY
# Verify the packaged identity, manifest flags, standalone ABI, icons and release binary.
python3 tools/validate_android_build.py "$BUILD_STAGE/arena_dash.apk" --mode "${MODE#--export-}" --expected-cert "${EXPECTED_CERT_SHA256:-}" --report "$BUILD_STAGE/validation.json"
# Copy to the destination filesystem before atomic publication; no sidecars in build/.
PUBLISH_STAGE=$(mktemp "$(dirname "$OUTPUT_FILE")/.arena-publish.XXXXXX")
trap 'rm -rf "$BUILD_STAGE"; rm -f "${PUBLISH_STAGE:-}"' EXIT
cp "$BUILD_STAGE/arena_dash.apk" "$PUBLISH_STAGE"
mv -f "$PUBLISH_STAGE" "$OUTPUT_FILE"
# Retain previous deliverables privately, leaving only the final validated APK.
python3 - "$SCRIPT_DIR" "$OUTPUT_FILE" <<'PY_ARCHIVE'
import hashlib
from pathlib import Path
import shutil
import sys
import time
root, final = map(Path, sys.argv[1:])
if final.parent.resolve() == (root / 'build').resolve():
    archive = root / '.maintenance/recovery/previous-apks'
    for previous in (root / 'build').glob('*.apk'):
        if previous.resolve() == final.resolve():
            continue
        if previous.is_symlink():
            raise SystemExit('Build cleanup blocked: unexpected APK symlink')
        archive.mkdir(parents=True, exist_ok=True, mode=0o700)
        digest = hashlib.sha256(previous.read_bytes()).hexdigest()
        destination = archive / (digest[:16] + '-' + previous.name)
        if destination.exists():
            destination = archive / (str(time.time_ns()) + '-' + destination.name)
        shutil.move(str(previous), str(destination))
        destination.chmod(0o600)
PY_ARCHIVE
REPORT_NAME=$(basename "$OUTPUT_FILE")
cp "$BUILD_STAGE/signature.txt" "qa/build-verification/$REPORT_NAME.signature.txt"
cp "$BUILD_STAGE/export.log" "qa/build-verification/$REPORT_NAME.export.log"
cp "$BUILD_STAGE/validation.json" "qa/build-verification/$REPORT_NAME.validation.json"
shasum -a 256 "$OUTPUT_FILE" > "qa/build-verification/$REPORT_NAME.sha256"
echo "Build complete: $OUTPUT_FILE"
ls -lh "$OUTPUT_FILE"
cat "qa/build-verification/$REPORT_NAME.sha256"
