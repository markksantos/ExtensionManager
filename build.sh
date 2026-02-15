#!/bin/bash
set -e

APP_NAME="Extension Manager"
BUNDLE_ID="com.markksantos.ExtensionManager"
BUILD_DIR=".build/debug"
APP_BUNDLE="${APP_NAME}.app"

echo "Building Extension Manager..."
swift build 2>&1

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BUILD_DIR}/ExtensionManager" "${APP_BUNDLE}/Contents/MacOS/ExtensionManager"

# Create Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ExtensionManager</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.markksantos.ExtensionManager</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Extension Manager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

# Create a simple app icon using SF Symbols rendered via Python
python3 -c "
import subprocess, os

# Create a simple iconset
iconset_dir = '${APP_BUNDLE}/Contents/Resources/AppIcon.iconset'
os.makedirs(iconset_dir, exist_ok=True)

# Use sips to create icon images from a base image
# For now, skip icon generation - the app will use the default icon
" 2>/dev/null || true

echo ""
echo "Build complete!"
echo "App bundle: $(pwd)/${APP_BUNDLE}"
echo ""
echo "To run:  open '${APP_BUNDLE}'"
echo "To install: cp -R '${APP_BUNDLE}' /Applications/"
