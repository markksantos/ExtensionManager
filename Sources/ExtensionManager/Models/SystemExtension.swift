import Foundation

/// Represents a single discovered macOS extension (plugin or system extension)
struct SystemExtension: Identifiable {
    let id: String // bundle identifier
    let bundleIdentifier: String
    let version: String
    let path: String
    let sdk: String
    let displayName: String
    let shortName: String
    let parentBundlePath: String
    let parentName: String
    let platform: String
    let category: ExtensionCategory
    let isEnabled: Bool
    let source: ExtensionSource

    var appName: String {
        if !parentName.isEmpty { return parentName }
        if !displayName.isEmpty { return displayName }
        let components = bundleIdentifier.split(separator: ".")
        if components.count >= 3 {
            // Use second-to-last for better names (e.g. com.google.drivefs -> drivefs)
            return String(components[components.count - 2]).capitalized
        }
        if components.count >= 2 {
            return String(components.last!)
        }
        return bundleIdentifier
    }

    var developerDomain: String {
        let components = bundleIdentifier.split(separator: ".")
        if components.count >= 2 {
            return String(components[0...1].joined(separator: "."))
        }
        return bundleIdentifier
    }

    var categoryDescription: String { category.description }

    var isUserInstalled: Bool {
        path.hasPrefix("/Applications") || path.contains("/Users/")
    }

    /// Whether this extension resolves to a real filesystem location that we
    /// can reveal in Finder or move to Trash. System extensions report no path
    /// (they are managed by the OS), so file actions are unavailable for them.
    var hasFileLocation: Bool {
        !path.isEmpty || !parentBundlePath.isEmpty
    }
}

// Custom Equatable/Hashable based on id only so List selection
// doesn't desync when isEnabled is toggled
extension SystemExtension: Hashable {
    static func == (lhs: SystemExtension, rhs: SystemExtension) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ExtensionSource: String, Hashable {
    case pluginKit = "PluginKit"
    case systemExtension = "System Extension"
}

// MARK: - Test Factory (internal)

extension SystemExtension {
     /// Internal convenience factory for tests.
     /// Public init is positional-only; this provides labeled params.
    static func make(
        bundleIdentifier: String = "com.test.example",
        version: String = "1.0",
        path: String = "/Applications/Test.appex",
        sdk: String = "com.apple.findersync",
        displayName: String = "Test Ext",
        shortName: String = "Test",
        parentBundlePath: String = "",
        parentName: String = "",
        platform: String = "macOS",
        category: ExtensionCategory = .finderSync,
        isEnabled: Bool = true,
        source: ExtensionSource = .pluginKit
    ) -> SystemExtension {
        SystemExtension(
            id: bundleIdentifier,
            bundleIdentifier: bundleIdentifier,
            version: version,
            path: path,
            sdk: sdk,
            displayName: displayName,
            shortName: shortName,
            parentBundlePath: parentBundlePath,
            parentName: parentName,
            platform: platform,
            category: category,
            isEnabled: isEnabled,
            source: source
        )
    }
}
