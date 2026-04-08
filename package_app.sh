#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

APP_NAME="InternTracker"
BUNDLE_NAME="${APP_NAME}.app"
BUNDLE_ID="com.jinzongxiao.interntracker"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$BUNDLE_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

SDK_PATH=""
for candidate in \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX15.5.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX15.2.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX14.5.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk" \
  "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
do
  if [[ -d "$candidate" ]]; then
    SDK_PATH="$candidate"
    break
  fi
done

if [[ -z "$SDK_PATH" ]]; then
  echo "No usable macOS SDK found in CommandLineTools." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swiftc \
  -sdk "$SDK_PATH" \
  -parse-as-library \
  Sources/*.swift \
  -o "$MACOS_DIR/$APP_NAME" \
  -framework SwiftUI \
  -framework AppKit

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

chmod +x "$MACOS_DIR/$APP_NAME"

# Ad-hoc sign for local launch convenience.
codesign --force --deep --sign - "$APP_DIR"

cd "$DIST_DIR"
zip -qry "${APP_NAME}.zip" "$BUNDLE_NAME"

echo "Packaged app: $APP_DIR"
echo "Packaged zip: $DIST_DIR/${APP_NAME}.zip"
