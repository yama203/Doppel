#!/bin/bash
set -e

APP_NAME="Doppel"
BUILD_DIR=".build"
APP_BUNDLE="$APP_NAME.app"

echo "==> Building $APP_NAME..."
swift build -c release

echo "==> Creating $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Copy icon
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

echo "==> Done! $APP_BUNDLE created."
echo "    You can open it with: open $APP_BUNDLE"
echo "    Or move it to /Applications: mv $APP_BUNDLE /Applications/"
