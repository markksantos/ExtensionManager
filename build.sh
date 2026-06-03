#!/bin/bash
set -euo pipefail

# Build script for Extension Manager.
#
#   ./build.sh            # debug build  -> "Extension Manager.app"
#   ./build.sh release    # release build (swift build -c release) + ad-hoc codesign
#
# The .app bundle is assembled by hand because SwiftPM only emits a bare
# executable. We generate an .icns icon and a code-signed bundle so the app
# launches as a proper macOS application (Dock icon, menu bar, Keychain, etc).

APP_NAME="Extension Manager"
BUNDLE_ID="com.markksantos.ExtensionManager"
APP_BUNDLE="${APP_NAME}.app"

CONFIG="debug"
if [[ "${1:-}" == "release" ]]; then
    CONFIG="release"
fi
BUILD_DIR=".build/${CONFIG}"

# Clean stale module cache (path changes when project directory name changes)
swift package clean 2>/dev/null || true

echo "Building Extension Manager (${CONFIG})..."
if [[ "${CONFIG}" == "release" ]]; then
    swift build -c release
else
    swift build
fi

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/ExtensionManager" "${APP_BUNDLE}/Contents/MacOS/ExtensionManager"

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
    <string>AppIcon.icns</string>
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

# ---------------------------------------------------------------------------
# Icon generation
# ---------------------------------------------------------------------------
# Render a 1024x1024 master PNG with AppKit, then expand to an .iconset and
# pack it into AppIcon.icns. AppKit drawing is used (not the C CoreGraphics
# helpers, which no longer exist in modern Swift) so this actually compiles.

echo "Generating app icon..."
ICON_SCRIPT="$(mktemp -t em_icongen).swift"
MASTER_PNG="$(mktemp -t em_icon).png"
cat > "${ICON_SCRIPT}" << 'SWIFT'
import AppKit

let args = CommandLine.arguments
let outPath = args.count > 1 ? args[1] : "/tmp/_em_icon.png"
let side: CGFloat = 1024

let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else {
    fputs("no cg context\n", stderr)
    exit(1)
}

// Rounded-rect app-tile background with a vertical blue gradient.
let inset: CGFloat = 80
let rect = CGRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
let path = CGPath(roundedRect: rect, cornerWidth: 180, cornerHeight: 180, transform: nil)
ctx.addPath(path)
ctx.clip()

let colors = [
    NSColor(srgbRed: 0.20, green: 0.45, blue: 0.98, alpha: 1).cgColor,
    NSColor(srgbRed: 0.08, green: 0.22, blue: 0.72, alpha: 1).cgColor,
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: colors,
                          locations: [0, 1])!
ctx.drawLinearGradient(gradient,
                       start: CGPoint(x: 0, y: side),
                       end: CGPoint(x: 0, y: 0),
                       options: [])

// Centered puzzle-piece glyph (SF Symbol) in white.
let symbolConfig = NSImage.SymbolConfiguration(pointSize: 460, weight: .semibold)
if let symbol = NSImage(systemSymbolName: "puzzlepiece.extension.fill",
                        accessibilityDescription: nil)?
    .withSymbolConfiguration(symbolConfig) {
    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    NSColor.white.set()
    let r = NSRect(origin: .zero, size: symbol.size)
    r.fill(using: .sourceOver)
    symbol.draw(in: r, from: .zero, operation: .destinationIn, fraction: 1)
    tinted.unlockFocus()

    let sz = tinted.size
    let drawRect = NSRect(x: (side - sz.width) / 2,
                          y: (side - sz.height) / 2,
                          width: sz.width, height: sz.height)
    tinted.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 0.96)
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to encode png\n", stderr)
    exit(1)
}
do {
    try png.write(to: URL(fileURLWithPath: outPath))
    print("icon written to \(outPath)")
} catch {
    fputs("write failed: \(error)\n", stderr)
    exit(1)
}
SWIFT

if swift "${ICON_SCRIPT}" "${MASTER_PNG}" && [ -f "${MASTER_PNG}" ]; then
    ICONSET="$(mktemp -d -t em_iconset).iconset"
    rm -rf "${ICONSET}"
    mkdir -p "${ICONSET}"
    # Apple's expected iconset layout (1x and 2x for each base size).
    sips -z 16 16     "${MASTER_PNG}" --out "${ICONSET}/icon_16x16.png"      >/dev/null
    sips -z 32 32     "${MASTER_PNG}" --out "${ICONSET}/icon_16x16@2x.png"   >/dev/null
    sips -z 32 32     "${MASTER_PNG}" --out "${ICONSET}/icon_32x32.png"      >/dev/null
    sips -z 64 64     "${MASTER_PNG}" --out "${ICONSET}/icon_32x32@2x.png"   >/dev/null
    sips -z 128 128   "${MASTER_PNG}" --out "${ICONSET}/icon_128x128.png"    >/dev/null
    sips -z 256 256   "${MASTER_PNG}" --out "${ICONSET}/icon_128x128@2x.png" >/dev/null
    sips -z 256 256   "${MASTER_PNG}" --out "${ICONSET}/icon_256x256.png"    >/dev/null
    sips -z 512 512   "${MASTER_PNG}" --out "${ICONSET}/icon_256x256@2x.png" >/dev/null
    sips -z 512 512   "${MASTER_PNG}" --out "${ICONSET}/icon_512x512.png"    >/dev/null
    cp "${MASTER_PNG}" "${ICONSET}/icon_512x512@2x.png"

    if iconutil -c icns "${ICONSET}" --output "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"; then
        echo "Icon created: AppIcon.icns"
    else
        echo "Note: iconutil conversion failed; app will use the default icon." >&2
    fi
    rm -rf "${ICONSET}"
else
    echo "Warning: icon generation failed; app will use the default icon." >&2
fi
rm -f "${ICON_SCRIPT}" "${MASTER_PNG}"

# ---------------------------------------------------------------------------
# Code signing
# ---------------------------------------------------------------------------
# Local/dev builds are ad-hoc signed so the bundle launches and Keychain works.
# For distribution, set CODESIGN_IDENTITY to a "Developer ID Application: ..."
# identity; we then sign with the Hardened Runtime and entitlements so the app
# can be notarized.
ENTITLEMENTS="ExtensionManager.entitlements"
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    echo "Code signing with Developer ID + Hardened Runtime..."
    codesign --force --deep --options runtime \
        --entitlements "${ENTITLEMENTS}" \
        --sign "${CODESIGN_IDENTITY}" "${APP_BUNDLE}" \
        && echo "Signed for distribution. Next: notarize with notarytool." \
        || { echo "ERROR: Developer ID signing failed." >&2; exit 1; }
else
    echo "Code signing (ad-hoc)..."
    codesign --force --deep --sign - "${APP_BUNDLE}" 2>/dev/null \
        && echo "Signed (ad-hoc). Set CODESIGN_IDENTITY for a distributable build." \
        || echo "Note: ad-hoc signing failed; app may still run locally." >&2
fi

echo ""
echo "Build complete!"
echo "App bundle: $(pwd)/${APP_BUNDLE}"
echo ""
echo "To run:     open '${APP_BUNDLE}'"
echo "To install: cp -R '${APP_BUNDLE}' /Applications/"
