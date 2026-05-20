#!/usr/bin/env bash
# Build a runnable .app bundle from the SPM executable.
#
# Usage:
#   ./scripts/build-app.sh                # release build into build/PortSheriff.app
#   ./scripts/build-app.sh debug          # debug build
#
# Output: build/PortSheriff.app
#
# Optional code signing — set these env vars before running:
#   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
#
# Notarization is not handled here. See docs/notarize.md (TODO) when certs are configured.

set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/PortSheriff.app"
BINARY_NAME="PortSheriff"

cd "$ROOT"

echo "==> swift build -c $CONFIG"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$BINARY_NAME"
if [[ ! -x "$BIN_PATH" ]]; then
    echo "Error: built binary not found at $BIN_PATH" >&2
    exit 1
fi

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BIN_PATH" "$APP/Contents/MacOS/$BINARY_NAME"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
    cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP/Contents/Info.plist"
fi

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    echo "==> Signing with: $CODESIGN_IDENTITY"
    codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP"
else
    echo "==> Ad-hoc signing (set CODESIGN_IDENTITY for a real cert)"
    codesign --force --sign - "$APP"
fi

echo
echo "Built: $APP"
echo "Run with: open '$APP'"
