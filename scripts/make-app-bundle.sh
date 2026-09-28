#!/usr/bin/env bash
#
# Bundle the Engram menu bar app into a standalone Engram.app with AppIcon.icns.
#
set -euo pipefail

VERSION="${1:-0.1.0}"
ARCH="${2:-arm64}"
BUILD="${3:-$VERSION}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Building release binary for $ARCH..."
swift build -c release --arch "$ARCH"

BIN_PATH="$(swift build -c release --arch "$ARCH" --show-bin-path)"
EXECUTABLE="$BIN_PATH/Engram"

if [ ! -x "$EXECUTABLE" ]; then
  echo "error: executable not found at $EXECUTABLE" >&2
  exit 1
fi

DIST="$ROOT/dist/$ARCH"
APP="$DIST/Engram.app"

rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$EXECUTABLE" "$APP/Contents/MacOS/Engram"

if [ -f "$ROOT/assets/AppIcon.icns" ]; then
  cp "$ROOT/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

if [ -d "$ROOT/assets" ]; then
  cp "$ROOT/assets/"* "$APP/Contents/Resources/" 2>/dev/null || true
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>Engram</string>
  <key>CFBundleIdentifier</key><string>org.unboundcognition.engram</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Engram</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$BUILD</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Signing bundle..."
codesign --force --deep -s - "$APP"

echo "Successfully built: $APP"
