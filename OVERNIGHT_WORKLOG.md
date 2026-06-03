# ExtensionManager — Overnight Worklog

## What it is

A native macOS SwiftUI utility (Swift Package Manager, macOS 13+) that scans,
categorizes, and manages all third-party system extensions and PluginKit
plugins installed on the Mac. It discovers extensions via `pluginkit -mDvvv`
and `systemextensionsctl list`, filters out Apple's own extensions, groups them
by category (Finder Sync, Share, Quick Look, Widgets, Network, Driver, Camera,
etc.), and shows bundle ID / version / path / parent app / SDK / enabled state
in a detail pane. PluginKit extensions can be toggled in-app; System Extensions
deep-link to System Settings. Optional one-line AI descriptions via the OpenAI
API (`gpt-4o-mini`), with the key stored in the macOS Keychain. Three display
modes (Dock / Menu Bar / Both) and a menu-bar extra.

## Starting state (honest starting completeness: ~65%)

Solid, real, Mark-authored codebase (NOT a third-party clone) — good
architecture (Models / ViewModels / Views / Scanner / Services), real Keychain
and OpenAI integration, NavigationSplitView UI, export-to-JSON, trash/reveal
actions. But it did not pass its own test suite and had broken peripheral
tooling:

- **Tests did not compile.** `make()` factory arguments were passed in the
  wrong order, and two `appName` assertions contradicted both each other and
  the implementation. `swift test` failed with a fatal error.
- **A real parser bug.** `parseSystemExtensionsOutput` parsed the verbatim
  column-header line (`enabled\tactive\tteamID\tbundleID (version)\tname\t[state]`)
  as data, creating a phantom extension literally named `bundleID` that showed
  up in the UI on any Mac with system extensions.
- **`build.sh` icon generation was a no-op stub** — it used removed C-style
  CoreGraphics APIs (`CGContextAddRect`, `boundingBox`, etc.) that do not
  compile, swallowed the failure with `2>/dev/null`, and shipped no icon.
- **`generate-xcodeproj.sh` was dead** — `swift package generate-xcodeproj`
  was removed from modern Swift; the script always failed, and the README told
  users to run it.
- **README was inaccurate** (`swift build` does not produce the `.app`; pointed
  at the dead Xcode-project flow).
- No scanner-parsing tests (the most fragile, real-world-facing code).
- No release/codesign path, no entitlements, no distribution story.
- App was never verified to launch.

## What I changed, fixed, added, built

### Real bug fixes
- **Phantom `bundleID` extension** — `Sources/ExtensionManager/Scanner/ExtensionScanner.swift`:
  skip the `bundleID (version)` column-header row in `parseSystemExtensionsOutput`.
  Verified gone in the live app.
- **File actions on System Extensions** — added `SystemExtension.hasFileLocation`
  (`Models/SystemExtension.swift`) and gated *Reveal in Finder* / *Move to Trash*
  on it in `Views/ExtensionDetailView.swift` and `Views/ExtensionRowView.swift`
  (system extensions report no path, so those actions always failed). Added a
  defensive guard in `ViewModels/ExtensionViewModel.moveToTrash` so it never
  calls `trashItem` on an empty path.

### Tests (now 38, all green; was 0 compiling)
- Fixed pre-existing compile errors and contradictory assertions in
  `Tests/ExtensionManagerTests/ExtensionManagerTests.swift`; added
  `hasFileLocation` tests.
- Added `Tests/ExtensionManagerTests/ExtensionScannerTests.swift` — 11 tests
  built from real `pluginkit`/`systemextensionsctl` output covering enabled/
  disabled flags, `(null)` versions, multi-block parsing, header-row skipping,
  category mapping, plus a live `scanAll()` smoke test asserting the result set
  is Apple-filtered and de-duplicated.
- Registered the test target in `Package.swift`.

### Build / icon / distribution
- Rewrote `build.sh`: a working AppKit icon renderer that produces a real
  puzzle-piece `AppIcon.icns` (full iconset, all sizes), a `release` mode
  (`./build.sh release`), ad-hoc signing for local runs, and Developer ID +
  Hardened Runtime signing via `CODESIGN_IDENTITY` against the new
  `ExtensionManager.entitlements`. Made it bash 3.2-safe.
- Added `ExtensionManager.entitlements` (non-sandboxed, `network.client` only)
  with an inline explanation of why MAS is not viable.
- Removed the dead `generate-xcodeproj.sh`.
- `ShellCommand.swift` now captures stderr and logs non-zero exits (prior
  uncommitted improvement, folded in).

### Docs
- Rewrote the install / Xcode / AI / tests / distribution sections of
  `README.md` to match reality.

## Current state

- **Builds?** Yes — `swift build` and `swift build -c release` both clean, zero
  warnings, from a wiped `.build`.
- **Runs?** Yes — `./build.sh release` produces a signed `Extension Manager.app`
  that launches, scans the real system (53 user extensions found), renders the
  sidebar/list/detail UI with correct icons and category badges, and quits
  cleanly. No crash reports. The phantom `bundleID` row is gone.
- **Tests?** 38 tests, 0 failures (`swift test`), including a live scan smoke
  test.
- **AI path?** Verified end-to-end with one trivial call using the exact
  `OpenAIService` request shape (HTTP 200, valid description). No key is
  committed — it is runtime-only, stored in Keychain.

## How to run it locally

```bash
cd "Extension Manager"        # the project dir
swift test                    # 38 tests
swift run                     # build + launch (dev)

# or a proper signed .app bundle:
./build.sh                    # debug, ad-hoc signed
./build.sh release            # optimized
open "Extension Manager.app"
```

Optional AI descriptions: open Settings (⌘,) and paste an OpenAI API key
(stored in Keychain).

## How to deploy (direct distribution — when ready)

The app is intentionally not sandboxed (it shells out to `pluginkit` /
`systemextensionsctl`), so the Mac App Store is not an option without a
rearchitecture. Ship it via Developer ID + notarization:

```bash
CODESIGN_IDENTITY="Developer ID Application: Mark Santos (TEAMID)" ./build.sh release
ditto -c -k --keepParent "Extension Manager.app" ExtensionManager.zip
xcrun notarytool submit ExtensionManager.zip \
    --apple-id "you@example.com" --team-id TEAMID --password APP_SPECIFIC_PW --wait
xcrun stapler staple "Extension Manager.app"
```

Then host the `.app` (DMG/zip) or publish a Homebrew Cask.

## NEEDS FROM MARK

- **Apple Developer ID + app-specific password** to code-sign with Hardened
  Runtime and notarize for distribution (build path is wired; only the
  credentials are missing). Local ad-hoc builds work without this.
- **Distribution decision:** confirm direct distribution (recommended; the app
  cannot be sandboxed for the MAS without dropping the core toggle/scan
  features).
- **OpenAI API key** only if you want the AI feature pre-filled; it is a
  runtime, user-entered, Keychain-stored setting and is not required to build,
  run, or test. (Verified working against a sibling-project key during this
  session; nothing was committed.)

## Honest completeness now: ~90%

Core product works end-to-end on real data, builds cleanly, is tested, has a
real icon, a real distribution path, and accurate docs.

What remains (all gated on Mark or genuinely out of scope for an unattended
run):
- Developer ID signing + notarization (needs Mark's Apple credentials).
- A Homebrew Cask / download page (needs a hosted, notarized artifact first).
- Nice-to-haves: live re-read of an extension's enabled state after toggling
  (currently an optimistic UI update), and richer error surfacing for
  `pluginkit -e` permission failures.
