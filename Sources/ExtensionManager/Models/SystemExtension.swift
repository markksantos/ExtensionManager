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
