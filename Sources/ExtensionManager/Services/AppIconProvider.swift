import AppKit
import SwiftUI

@MainActor
class AppIconProvider: ObservableObject {
    static let shared = AppIconProvider()

    private var cache: [String: NSImage] = [:]

    /// Returns the app icon for the given extension. Size is NOT baked into
    /// the cached image — callers should use SwiftUI .frame() to size it.
    func icon(for ext: SystemExtension) -> NSImage {
        if let cached = cache[ext.bundleIdentifier] {
            return cached
        }
        let image = resolveIcon(for: ext)
        cache[ext.bundleIdentifier] = image
        return image
    }

    private func resolveIcon(for ext: SystemExtension) -> NSImage {
        // Try parent bundle path first
        if !ext.parentBundlePath.isEmpty {
            let appPath = findTopLevelApp(ext.parentBundlePath)
            if FileManager.default.fileExists(atPath: appPath), appPath.hasSuffix(".app") {
                return NSWorkspace.shared.icon(forFile: appPath)
            }
        }

        // Try the extension path
        if !ext.path.isEmpty {
            let appPath = findTopLevelApp(ext.path)
            if appPath.hasSuffix(".app"), FileManager.default.fileExists(atPath: appPath) {
                return NSWorkspace.shared.icon(forFile: appPath)
            }
        }

        // Try finding by parent bundle ID
        let parentBundleID = deriveParentBundleID(from: ext.bundleIdentifier)
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: parentBundleID) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }

        // Try base bundle ID (first 3 components)
        let baseBundleID = baseParentBundleID(from: ext.bundleIdentifier)
        if baseBundleID != parentBundleID,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: baseBundleID) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }

        return NSWorkspace.shared.icon(for: .applicationBundle)
    }

    private func findTopLevelApp(_ path: String) -> String {
        let components = path.components(separatedBy: "/")
        for i in 0..<components.count {
            if components[i].hasSuffix(".app") {
                return components[0...i].joined(separator: "/")
            }
        }
        return path
    }

    private func deriveParentBundleID(from bundleID: String) -> String {
        let parts = bundleID.split(separator: ".")
        if parts.count > 3 {
            return parts.dropLast().joined(separator: ".")
        }
        return bundleID
    }

    private func baseParentBundleID(from bundleID: String) -> String {
        let parts = bundleID.split(separator: ".")
        if parts.count >= 3 {
            return parts.prefix(3).joined(separator: ".")
        }
        return bundleID
    }

    func clearCache() {
        cache.removeAll()
    }
}

/// SwiftUI view that displays an app icon for an extension
struct AppIconView: View {
    let ext: SystemExtension
    let size: CGFloat
    private let provider = AppIconProvider.shared

    init(extension ext: SystemExtension, size: CGFloat = 32) {
        self.ext = ext
        self.size = size
    }

    var body: some View {
        Image(nsImage: provider.icon(for: ext))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}
