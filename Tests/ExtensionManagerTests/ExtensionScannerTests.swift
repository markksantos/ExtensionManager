import XCTest
@testable import ExtensionManager

/// Parser tests built from real `pluginkit -mDvvv` and `systemextensionsctl list`
/// output. These exercise the fragile text-parsing layer without shelling out,
/// so they are deterministic on CI.
final class ExtensionScannerTests: XCTestCase {
    private let scanner = ExtensionScanner()

    // MARK: - PluginKit parsing

    func test_pluginkit_parses_enabled_block_with_parent() {
        let output = """
        +    com.acme.Notes.SharingExtension(4.13)
        \t            Path = /Applications/Acme Notes.app/Contents/PlugIns/Sharing.appex
        \t            UUID = 403BDD1F-C78E-5DC0-8FDB-688DE5C9035C
        \t             SDK = com.apple.share-services
        \t   Parent Bundle = /Applications/Acme Notes.app
        \t    Display Name = Acme Notes
        \t      Short Name = Sharing
        \t     Parent Name = Acme Notes
        \t        Platform = macOS
        """
        let exts = scanner.parsePluginKitOutput(output)
        XCTAssertEqual(exts.count, 1)
        let e = exts[0]
        XCTAssertEqual(e.bundleIdentifier, "com.acme.Notes.SharingExtension")
        XCTAssertEqual(e.version, "4.13")
        XCTAssertEqual(e.sdk, "com.apple.share-services")
        XCTAssertEqual(e.category, .shareServices)
        XCTAssertEqual(e.parentName, "Acme Notes")
        XCTAssertEqual(e.parentBundlePath, "/Applications/Acme Notes.app")
        XCTAssertEqual(e.displayName, "Acme Notes")
        XCTAssertTrue(e.isEnabled)
        XCTAssertEqual(e.source, .pluginKit)
    }

    func test_pluginkit_disabled_flag_marks_disabled() {
        let output = """
        -    com.example.disabled.ext(1.0)
        \t            Path = /Applications/Example.app/Contents/PlugIns/X.appex
        \t             SDK = com.apple.findersync
        """
        let exts = scanner.parsePluginKitOutput(output)
        XCTAssertEqual(exts.count, 1)
        XCTAssertFalse(exts[0].isEnabled)
        XCTAssertEqual(exts[0].category, .finderSync)
    }

    func test_pluginkit_no_flag_is_enabled() {
        let output = """
             com.example.noflag.ext(2.1)
        \t             SDK = com.apple.widgetkit
        """
        let exts = scanner.parsePluginKitOutput(output)
        XCTAssertEqual(exts.count, 1)
        XCTAssertTrue(exts[0].isEnabled)
        XCTAssertEqual(exts[0].category, .widgetKit)
    }

    func test_pluginkit_null_version_becomes_empty() {
        let output = """
             com.example.nullver.ext((null))
        \t             SDK = com.apple.quicklook.preview
        """
        let exts = scanner.parsePluginKitOutput(output)
        XCTAssertEqual(exts.count, 1)
        XCTAssertEqual(exts[0].version, "")
        XCTAssertEqual(exts[0].category, .quickLookPreview)
    }

    func test_pluginkit_parses_multiple_blocks() {
        let output = """
        +    com.first.ext(1.0)
        \t             SDK = com.apple.findersync
        \t    Display Name = First

             com.second.ext(2.0)
        \t             SDK = com.apple.widgetkit
        \t    Display Name = Second
        """
        let exts = scanner.parsePluginKitOutput(output)
        XCTAssertEqual(exts.count, 2)
        XCTAssertEqual(exts[0].bundleIdentifier, "com.first.ext")
        XCTAssertEqual(exts[1].bundleIdentifier, "com.second.ext")
        XCTAssertEqual(exts[1].category, .widgetKit)
    }

    func test_pluginkit_empty_output_returns_empty() {
        XCTAssertTrue(scanner.parsePluginKitOutput("").isEmpty)
    }

    // MARK: - System extension parsing

    func test_systemextensions_parses_enabled_driver() {
        let output = """
        2 extension(s)
        --- com.apple.system_extension.driver_extension (Go to Settings to modify)
        enabled\tactive\tteamID\tbundleID (version)\tname\t[state]
        *\t*\tQED4VVPZWA\tcom.logi.ghub.hidfilter (1.1.15.661881/1.1.15)\tLogitech G HUB HID Driver Extension\t[activated enabled]
        """
        let exts = scanner.parseSystemExtensionsOutput(output)
        XCTAssertEqual(exts.count, 1)
        let e = exts[0]
        XCTAssertEqual(e.bundleIdentifier, "com.logi.ghub.hidfilter")
        XCTAssertEqual(e.version, "1.1.15.661881/1.1.15")
        XCTAssertEqual(e.displayName, "Logitech G HUB HID Driver Extension")
        XCTAssertEqual(e.category, .driverExtension)
        XCTAssertTrue(e.isEnabled)
        XCTAssertEqual(e.source, .systemExtension)
    }

    func test_systemextensions_disabled_network_extension() {
        // Leading empty "enabled" column (tab first) means not user-enabled,
        // even though it is loaded/active in memory.
        let output = """
        --- com.apple.system_extension.network_extension (Go to Settings)
        enabled\tactive\tteamID\tbundleID (version)\tname\t[state]
        \t*\tH84YML94ZH\tnet.example.vpn.Tunnel (1.0/1)\tExample VPN Tunnel\t[activated disabled]
        """
        let exts = scanner.parseSystemExtensionsOutput(output)
        XCTAssertEqual(exts.count, 1)
        let e = exts[0]
        XCTAssertEqual(e.bundleIdentifier, "net.example.vpn.Tunnel")
        XCTAssertEqual(e.category, .networkExtension)
        XCTAssertFalse(e.isEnabled)
    }

    func test_systemextensions_camera_extension() {
        let output = """
        --- com.apple.system_extension.cmio (Go to Settings)
        enabled\tactive\tteamID\tbundleID (version)\tname\t[state]
        *\t*\t2MMRE5MTB8\tcom.obsproject.obs-studio.mac-camera-extension (32.1.2/24742303888)\tOBS Virtual Camera\t[activated enabled]
        """
        let exts = scanner.parseSystemExtensionsOutput(output)
        XCTAssertEqual(exts.count, 1)
        XCTAssertEqual(exts[0].category, .cameraExtension)
        XCTAssertTrue(exts[0].isEnabled)
    }

    func test_systemextensions_ignores_header_and_count_lines() {
        let output = """
        0 extension(s)
        --- com.apple.system_extension.driver_extension (Go to Settings)
        enabled\tactive\tteamID\tbundleID (version)\tname\t[state]
        """
        XCTAssertTrue(scanner.parseSystemExtensionsOutput(output).isEmpty)
    }

    // MARK: - End-to-end (de-dup + Apple filtering)

    func test_scanAll_filters_apple_and_dedupes() async {
        // Live smoke check: a real Mac has at least some non-Apple extensions
        // and the result set must never contain Apple bundles or duplicates.
        let results = await scanner.scanAll()
        XCTAssertFalse(results.contains { $0.bundleIdentifier.hasPrefix("com.apple.") },
                       "Apple extensions must be filtered out")
        let ids = results.map(\.bundleIdentifier)
        XCTAssertEqual(ids.count, Set(ids).count, "results must be de-duplicated")
    }
}
