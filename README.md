<div align="center">

# Extension Manager

**macOS app to discover, browse, and manage all system extensions and plugins on your Mac**

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](#)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-007AFF?style=for-the-badge&logo=apple&logoColor=white)](#)
[![macOS](https://img.shields.io/badge/macOS-13.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](#)

</div>

---

## Features

- **Extension Discovery** — Scans PluginKit plugins and System Extensions to find all third-party extensions on your Mac
- **Category Browsing** — Extensions organized by category (Finder, Share, Network, Content Blockers, etc.)
- **Detail View** — See bundle identifier, version, path, parent app, SDK, and enabled/disabled status
- **Enable/Disable** — Toggle PluginKit extensions on or off directly from the app
- **AI Descriptions** — Optional AI-powered descriptions via OpenAI to explain what each extension does
- **Menu Bar Extra** — Quick access from the macOS menu bar with extension count
- **Flexible Display** — Run as a dock app, menu bar app, or both
- **Smart Filtering** — Automatically filters out Apple system extensions, shows only user-installed

## Getting Started

### Prerequisites

- macOS 13.0+
- Xcode 15+ / Swift 5.9+ (for building from source)

### Run from Source (quick)

```bash
git clone https://github.com/markksantos/ExtensionManager.git
cd ExtensionManager
swift run        # builds and launches the app
```

`swift build` only produces a bare executable. To get a proper `.app`
bundle (Dock icon, app icon, menu bar, code signature) use the build script
below or open `Package.swift` directly in Xcode and run.

### Build the App Bundle

```bash
chmod +x build.sh
./build.sh            # debug build  -> "Extension Manager.app" (ad-hoc signed)
./build.sh release    # optimized release build
open "Extension Manager.app"
cp -R "Extension Manager.app" /Applications/   # for a permanent install
```

`build.sh` assembles the `.app`, generates the icon (`AppIcon.icns`), and
ad-hoc code-signs the bundle so it launches locally with Keychain access.

### Open in Xcode

Swift Package Manager projects open natively in Xcode — just open
`Package.swift`. (The old `swift package generate-xcodeproj` command was
removed from modern Swift toolchains, so there is no separate `.xcodeproj`.)

### Install via Homebrew Cask (future)

When distributed as a notarized Homebrew Cask:

```bash
brew install --cask extension-manager
```

For now, build the `.app` and drag it to `/Applications`.

## AI Descriptions (optional)

The detail pane can show a one-line, AI-generated explanation of what each
extension does. To enable it, open **Settings** (⌘,) and paste an
[OpenAI API key](https://platform.openai.com/api-keys). The key is stored in
the macOS **Keychain** (never on disk in plaintext) and is only used to call
`gpt-4o-mini`. Leave it blank to keep the app fully offline.

## Run the Tests

```bash
swift test
```

The suite covers SDK-to-category mapping, `pluginkit`/`systemextensionsctl`
output parsing (built from real-world samples), and a live smoke check that a
scan returns a de-duplicated, Apple-filtered result set.

## Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| Build | Swift Package Manager |
| Scanning | pluginkit CLI, systemextensionsctl |
| Security | Keychain (API key storage) |
| Platform | macOS 13.0+ |

## Distribution

Extension Manager is **not** App-Sandboxed — it shells out to `pluginkit` and
`systemextensionsctl`, which the App Sandbox forbids. That rules out the Mac
App Store without a rearchitecture, so the app is distributed directly:

1. Build an optimized bundle: `./build.sh release`
2. Sign with a Developer ID identity and the Hardened Runtime:
   ```bash
   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build.sh release
   ```
   (This signs against `ExtensionManager.entitlements`.)
3. Notarize the bundle:
   ```bash
   ditto -c -k --keepParent "Extension Manager.app" ExtensionManager.zip
   xcrun notarytool submit ExtensionManager.zip \
       --apple-id "you@example.com" --team-id TEAMID --password APP_SPECIFIC_PW --wait
   xcrun stapler staple "Extension Manager.app"
   ```

> **Note on toggling:** PluginKit extensions can be enabled/disabled in-app via
> `pluginkit -e use|ignore`. System Extensions (VPN, drivers, camera) are
> managed by the OS — the app deep-links you to the relevant
> *System Settings → Login Items & Extensions* pane instead.

## License

MIT License &copy; 2025 Mark Santos
